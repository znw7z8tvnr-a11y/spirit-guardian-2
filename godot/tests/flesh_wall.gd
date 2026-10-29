extends SceneTree
const Castle=preload("res://experiments/chain_lab/flesh_castle.gd")
var checks: Array[String]=[]
var failures: Array[String]=[]
var soaks: Array=[]
func _initialize() -> void:call_deferred("run")
func check(ok: bool,message: String) -> void:
 if ok:checks.append(message)
 else:failures.append(message)
func run() -> void:
 var castle=Castle.new();root.add_child(castle)
 check(castle.wall_hp==360 and castle.hp==100,"new run has a 360 wall before a 100 core")
 castle.take_damage(40)
 check(castle.wall_hp==320 and castle.hp==100,"intact wall absorbs incoming damage before core")
 castle.take_damage(360)
 check(castle.wall_hp==0 and not castle.wall_active and castle.hp==60,"overflow damage transfers once to the core")
 castle.set_auto(false);castle.absorb(100)
 check(castle.flesh==100 and castle.levels.atk==0,"manual mode retains all absorbed meat without hidden purchases")
 check(castle.upgrade("atk") and castle.flesh==94 and castle.attack_multiplier()==1.5,"source-cost attack upgrade consumes six meat and boosts all spell base power")
 check(castle.cost("atk")==13,"upgrade cost increases by seven per same-stat level")
 check(castle.upgrade("hp") and castle.wall_max==425 and castle.wall_hp==65,"HP upgrade increases current and maximum wall by sixty-five")
 check(not castle.wall_active,"partial repairs do not instantly flicker broken wall back on")
 castle.upgrade("regen");castle.recover(10)
 check(castle.wall_hp==85 and castle.wall_active,"wall reactivates after repair reaches twenty percent")
 castle.wall_hp=castle.wall_max;castle.recover(10)
 check(castle.hp==80,"regeneration repairs core after the wall is full")
 castle.upgrade("armor")
 check(is_equal_approx(castle.reduction(),0.14),"armor level reduces incoming damage by fourteen percent")
 castle.levels.armor=99
 check(castle.reduction()==0.70,"defense is capped at seventy percent")
 castle.flesh=0;var before: Dictionary=castle.levels.duplicate()
 check(not castle.upgrade("atk") and castle.levels==before,"insufficient meat never changes upgrade levels")
 castle.take_damage(100000);castle.recover(1000)
 check(castle.hp==0,"regeneration cannot resurrect a destroyed core")
 castle.reset();castle.absorb(24)
 check(castle.levels=={"atk":1,"hp":1,"armor":1,"regen":1} and castle.flesh==0,"automatic round-robin purchases all four growth types exactly once")
 castle.absorb(4);castle.reset()
 check(castle.total_absorbed==0 and castle.flesh==0 and castle.attack_multiplier()==1 and castle.wall_max==360,"new run clears meat, upgrades and wall growth")
 root.remove_child(castle);castle.queue_free();await process_frame
 var game=load("res://experiments/chain_lab/main.tscn").instantiate();game.persist_book=false;root.add_child(game);current_scene=game
 game.set_physics_process(false)
 game.wave=1;game.remaining=5
 var enemy: Node2D=game.spawn_enemy();enemy.kind=0;enemy.position=game.CENTER+Vector2(20,0)
 game.on_enemy_died(enemy);game.on_enemy_died(enemy)
 check(game.kills==1 and game.pending_flesh.size()==1,"one enemy awards one drop even if death is reported twice")
 var drop_id: int=game.pending_flesh.keys()[0]
 game.collect_flesh(drop_id);game.collect_flesh(drop_id)
 check(game.tower.total_absorbed==4,"pickup callback cannot double-credit the same meat")
 enemy.free();game.wave=5;game.remaining=9
 var boss: Node2D=game.spawn_enemy();game.on_enemy_died(boss);game.collect_all_flesh()
 check(game.tower.total_absorbed==52,"Boss awards forty-eight meat in addition to prior ordinary drop")
 boss.free()
 check(game.effective_attack_period()==1.1,"arcane-only starter gets a short primary interval")
 game.chain.load_kit();check(game.effective_attack_period()==game.attack_period,"long chain retains the selected paced interval")
 for expected in [2.0,4.0,8.0,1.0]:
  game.cycle_speed();check(Engine.time_scale==expected,"global simulation speed cycles to %dx" % int(expected))
 game.cycle_speed();game.cycle_speed();game.cycle_speed()
 var health_before: float=game.tower.wall_hp;game.user_paused=true;var time_before: float=game.combat_seconds
 game._physics_process(2)
 check(game.combat_seconds==time_before and game.tower.wall_hp==health_before,"pause blocks game clock and regeneration even at eight times speed")
 game.user_paused=false;game.open_growth();game._physics_process(2)
 check(game.combat_seconds==time_before,"wall upgrade menu pauses actual combat")
 root.remove_child(game);game.queue_free();await process_frame
 check(Engine.time_scale==1.0,"leaving the trial restores normal global speed")
 # Real battles with starter arcane only: no kit, no debug damage, no manual upgrades.
 for seed_value in [12032,24064,32012]:
  var live=load("res://experiments/chain_lab/main.tscn").instantiate();live.persist_book=false;root.add_child(live);current_scene=live
  live.rng.seed=seed_value;live.chain.rng.seed=seed_value+19980;live.rewards.rng.seed=seed_value+31000
  var frames:=0
  while live.wave<4 and not live.over and frames<10800:
   if live.rewards.pending>0:
    for index in live.rewards.offers.size():
     if live.rewards.offers[index].kind=="gem":live.rewards.choose(index);break
   await physics_frame;frames+=1
  live.collect_all_flesh()
  check(live.wave>=4 and live.tower.hp>0,"arcane starter clears wave three and claims an unequipped earned gem with seed %d" % seed_value)
  check(not live.chain.kit_loaded and live.chain.items.size()==2 and live.chain.slots==[0,-1,-1,-1,-1,-1,-1,-1,-1,-1],"seed %d survival uses no training inventory" % seed_value)
  check(live.tower.total_absorbed>=72 and live.tower.attack_multiplier()>1 and live.tower.regeneration()>0,"seed %d kills feed actual attack, defense and recovery growth" % seed_value)
  soaks.append({"seed":seed_value,"seconds":live.combat_seconds,"wave":live.wave,"kills":live.kills,"core":live.tower.hp,"wall":live.tower.wall_hp,"wall_max":live.tower.wall_max,"absorbed":live.tower.total_absorbed,"levels":live.tower.levels.duplicate(),"kit":live.chain.kit_loaded})
  root.remove_child(live);live.queue_free();await process_frame
 print("FLESH_RESULT "+JSON.stringify({"engine":Engine.get_version_info().string,"checks":checks,"failures":failures,"early_battles":soaks}))
 paused=false;quit(0 if failures.is_empty() else 1)
