extends SceneTree
const Gate=preload("res://experiments/chain_lab/wave_gate.gd")
const Store=preload("res://experiments/chain_lab/checkpoint_store.gd")
var checks: Array=[]
var failures: Array=[]
func _initialize() -> void:call_deferred("run")
func check(ok: bool,message: String) -> void:
 if ok:checks.append(message)
 else:failures.append(message)
func fixture() -> Node:
 var game=load("res://experiments/chain_lab/main.tscn").instantiate();game.persist_book=false;game.persist_run=false;root.add_child(game);return game
func run() -> void:
 var store:=Store.new();store.clear()
 var game:=fixture();game.set_process(false);game.set_physics_process(false)
 check(Gate.blocked_by(game)=="" and not game.buttons.NextWave.disabled,"fresh arcane-only opening offers a real early-start control")
 var before: Dictionary={"hp":game.tower.hp,"wall":game.tower.wall_hp,"items":game.chain.items.size(),"rng":game.rewards.rng.state}
 check(game.request_early_wave() and game.wave==0 and game.rest==0,"request only consumes waiting time, not a wave or reward")
 check(not game.request_early_wave(),"repeat request before the next physics tick cannot queue another wave")
 game._physics_process(1.0/60)
 check(game.wave==1 and game.remaining==5 and game.rewards.pending==0 and game.rewards.completed.is_empty(),"existing physics loop starts wave one exactly once without inventing a clear")
 check(game.tower.hp==before.hp and game.tower.wall_hp==before.wall and game.chain.items.size()==before.items and game.rewards.rng.state==before.rng,"opening skip grants no healing, loot, flesh or reward RNG draw")
 check(not game.request_early_wave(),"live spawn queue blocks early starts")
 game.rng.seed=12032;game.chain.rng.seed=32012;game.rewards.rng.seed=43032;game.resolver.rng.seed=54032
 game.cycle_speed();game.cycle_speed();game.cycle_speed();game.set_process(true);game.set_physics_process(true)
 var ticks:=0
 while not Gate.blocked_by(game).is_empty() and not game.over and ticks<3000:await physics_frame;ticks+=1
 game.set_process(false);game.set_physics_process(false)
 check(game.wave==1 and game.rewards.completed.has(1) and Gate.blocked_by(game).is_empty(),"real first-wave combat reaches a cleared intermission")
 game.persist_run=true
 check(game.request_early_wave(),"cleared intermission accepts one request")
 var saved:=store.load_checkpoint()
 check(saved.ok and saved.data.game.wave==1 and saved.data.game.rest>0,"latest safe wave and original rest are saved before combat resumes")
 check(not game.request_early_wave(),"a second intermission tap cannot skip wave two")
 game._physics_process(1.0/60)
 check(game.wave==2 and game.remaining==6 and game.rewards.completed.size()==1,"early start increments exactly one wave through the normal spawning path")
 var clone:=fixture();clone.set_process(false);clone.set_physics_process(false)
 check(store.apply(clone,saved.data) and clone.wave==1 and Gate.blocked_by(clone).is_empty(),"saved intermission restores a usable gate without pretending wave two was cleared")
 clone.queue_free();store.clear();game.persist_run=false;game.set_process(true);game.set_physics_process(true)
 ticks=0
 while game.rewards.pending==0 and not game.over and ticks<4000:
  if Gate.blocked_by(game).is_empty():game.request_early_wave()
  await physics_frame;ticks+=1
 game.set_process(false);game.set_physics_process(false)
 check(game.wave==3 and game.rewards.pending==1,"real third wave still grants its original single selection")
 check(not game.request_early_wave() and Gate.blocked_by(game)=="reward","unclaimed real reward cannot be bypassed")
 game.rewards.choose(0)
 check(game.edit_open and not game.request_early_wave(),"post-reward equipment confirmation cannot be bypassed")
 game.buttons.Done.pressed.emit()
 check(Gate.blocked_by(game).is_empty(),"real confirmation releases the settled intermission")
 var original_rest: float=game.rest
 for kind in ["pause","growth","resume","training","drill","active","pending","shot","flesh","enemy","unsettled"]:
  match kind:
   "pause":game.user_paused=true
   "growth":game.growth_open=true
   "resume":game.resume_pending=true
   "training":game.chain.kit_loaded=true
   "drill":game.enemy_drill=true
   "active":game.chain.active={"test":true}
   "pending":game.chain.pending=[{"test":true}]
   "shot":game.shots.add_child(Node2D.new())
   "flesh":game.pending_flesh[999]={}
   "enemy":game.enemies.add_child(Node2D.new())
   "unsettled":game.rewards.completed.erase(3)
  check(not game.request_early_wave() and game.rest==original_rest,"blocked request preserves intermission: "+kind)
  game.user_paused=false;game.growth_open=false;game.resume_pending=false;game.chain.kit_loaded=false;game.enemy_drill=false;game.chain.active={};game.chain.pending=[];game.pending_flesh.clear();game.rewards.completed[3]=true
  for parent in [game.shots,game.enemies]:
   for actor in parent.get_children():parent.remove_child(actor);actor.queue_free()
 game.wave=20;game.rewards.completed[20]=true
 check(not game.request_early_wave() and game.wave==20,"final wave cannot be advanced to twenty-one")
 game.over=true;check(not game.request_early_wave(),"finished run rejects the control")
 game.queue_free();await process_frame;store.clear()
 print("EARLYWAVE_RESULT "+JSON.stringify({"checks":checks,"failures":failures}));quit(0 if failures.is_empty() else 1)
