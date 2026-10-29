extends SceneTree
class Dummy:
 extends Node2D
 var dead:=false
var checks: Array[String]=[]
var failures: Array[String]=[]
var emitted: Array=[]
func _initialize() -> void:call_deferred("run")
func check(ok: bool, message: String) -> void:
 if ok:checks.append(message)
 else:failures.append(message)
func record(slot: int,item: Dictionary,target: Node2D,cycle: Dictionary, context: Dictionary) -> void:emitted.append({"slot":slot,"item":item,"target":target,"run":cycle,"context":context})
func complete(model: Node, event: Dictionary) -> void:model.complete_skill(int(event.slot),event.target,{"position":event.context.aim,"hit":is_instance_valid(event.target) and not event.target.dead,"element":event.item.key},event.run,event.context)
func run() -> void:
 var game=load("res://experiments/chain_lab/main.tscn").instantiate();game.persist_book=false;root.add_child(game);current_scene=game
 game.set_physics_process(false);game.set_process(false);game.enemies.process_mode=Node.PROCESS_MODE_DISABLED
 var m: Node=game.chain
 m.cast_requested.disconnect(game.cast_spell);m.resonance_requested.disconnect(game.resonate);m.cast_requested.connect(record)
 check(m.slots.size()==10 and m.slots[0]==0 and m.items.size()==1,"fresh run owns only arcane in ten slots")
 check(m.discovered.is_empty() and game.buttons.Arrange.disabled,"unknown resonance is hidden and special arrangement locked")
 check(not m.equip(10,0) and not m.equip(-1,0),"slot capacity rejects out-of-range edits")
 m.load_kit();m.load_kit()
 check(m.items.size()==10,"training kit is idempotent and grants no duplicate items")
 check(not m.equip(0,1),"root cannot become a gem")
 check(not m.equip(9,2),"one inventory item cannot equip twice")
 check(not m.connect_slots(2,3),"skill to skill is rejected")
 check(not m.connect_slots(1,4),"gem to gem is rejected")
 check(not m.connect_slots(5,1),"cycle and occupied incoming edge are rejected")
 check(m.equip(8,9) and not m.connect_slots(1,8),"tier-three gem cannot exceed two outgoing branches")
 check(not m.equip(1,9),"downgrading a branching gem requires removing extra branch")
 check(m.equip(0,8) and int(m.item_at(0).level)==3,"held tier-three attack can replace root skill")
 m.equip(0,0);m.load_kit()
 # Guaranteed gem fixtures isolate scheduling tests from probability outcomes.
 m.items[4].level=3;m.items[6].level=3
 var target:=Dummy.new();target.position=game.CENTER;game.enemies.add_child(target)
 m.resonance_chance=1.0;m.resonance_cooldown=8.0
 check(m.start(target),"root starts a single active attack cycle")
 check(not m.start(target),"new primary attack cannot overlap unfinished chain")
 complete(m,emitted.pop_front());m.advance(0.33)
 check(emitted.is_empty(),"gem stage delays next attacks instead of instant burst")
 m.advance(0.33)
 check(emitted.size()==2,"tier-three gem fans out into two real skill casts")
 var a: Dictionary=emitted.pop_front();var b: Dictionary=emitted.pop_front()
 complete(m,a);complete(m,b);m.advance(0.33);m.advance(0.33)
 check(emitted.size()==2,"both alternating branches continue through their gems")
 for e in emitted.duplicate():complete(m,e)
 emitted.clear()
 check(m.resonances==1 and m.rolls==1,"elements across branches share exactly one resonance roll")
 check("fire+ice+lightning" in m.discovered,"recipe is discovered only after successful actual casts")
 check(m.active.is_empty(),"cycle completes after all branches settle")
 # Start inside cooldown; even a guaranteed roll cannot produce another resonance.
 m.start(target);complete(m,emitted.pop_front());m.advance(0.33);m.advance(0.33)
 for e in emitted.duplicate():complete(m,e)
 emitted.clear();m.advance(0.33);m.advance(0.33)
 for e in emitted.duplicate():complete(m,e)
 emitted.clear()
 check(m.resonances==1 and m.rolls==1,"cooldown suppresses repeat resonance across cycles")
 # A target dies after root impact; continuation must stay near the last hit.
 m.reset_runtime();m.load_kit();m.start(target);complete(m,emitted.pop_front())
 target.dead=true
 var near:=Dummy.new();near.position=target.position+Vector2(80,0);game.enemies.add_child(near)
 m.advance(0.33);m.advance(0.33)
 check(emitted.size()==2 and emitted[0].target==near and m.retargets>0,"dead target transfers both remaining branches to nearby enemy")
 emitted.clear();m.reset_runtime();near.dead=true;target.dead=false
 m.start(target);complete(m,emitted.pop_front());target.dead=true
 var far:=Dummy.new();far.position=target.position+Vector2(900,0);game.enemies.add_child(far)
 m.advance(0.33);m.advance(0.33)
 check(emitted.size()==2 and emitted[0].target==null and emitted[1].target==null,"no nearby target preserves both branches as ground casts without reaching distant enemy")
 m.load_kit();m.random_arrange()
 var used: Array=[];var valid:=true
 for id in m.slots:
  if id>=0:
   if id in used:valid=false
   used.append(id)
 for edge in m.edges:
  if m.item_at(edge.from).kind==m.item_at(edge.to).kind:valid=false
 check(valid and used.size()<=10,"random arrangement obeys capacity, inventory and alternating types")
 root.remove_child(game);game.queue_free();await process_frame
 var live=load("res://experiments/chain_lab/main.tscn").instantiate();live.persist_book=false;root.add_child(live);current_scene=live
 live.rng.seed=12032;live.chain.rng.seed=32012;live.rewards.rng.seed=43032
 live.chain.load_kit();live.chain.resonance_chance=1.0
 for i in 3600:
  if live.rewards.pending>0:live.rewards.choose(0)
  await physics_frame
 check(live.chain.casts>=8 and live.kills>0,"real sixty-second battle soak launches chained spells and kills enemies")
 check(live.chain.resonances>0 and live.chain.discovered.size()>0,"real battle discovers resonance from actual impacts")
 check(live.enemies.get_child_count()<=40 and live.shots.get_child_count()<=10,"battle soak respects enemy and projectile bounds")
 check(live.tower.hp>0 and live.wave>=2,"trial balance survives and progresses beyond first wave with kit")
 var soak={"wave":live.wave,"kills":live.kills,"hp":live.tower.hp,"casts":live.chain.casts,"resonances":live.chain.resonances,"retargets":live.chain.retargets}
 while live.rewards.pending>0:live.rewards.choose(0)
 live.set_physics_process(false)
 live.wave=5;live.remaining=9
 var boss: Node2D=live.spawn_enemy()
 check(boss.kind==5 and boss.max_hp==425,"every fifth wave spawns the tuned boss")
 live.chain.reset_runtime()
 for e in live.enemies.get_children():e.free()
 live.wave=20;live.remaining=0;live.rest=0
 live._physics_process(0.1)
 check(live.over and live.wave==20,"clearing final wave ends trial without starting wave twenty-one")
 print("CHAINLAB_RESULT "+JSON.stringify({"engine":Engine.get_version_info().string,"checks":checks,"failures":failures,"soak":soak}))
 paused=false;quit(0 if failures.is_empty() else 1)
