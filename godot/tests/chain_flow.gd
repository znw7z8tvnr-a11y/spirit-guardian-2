extends SceneTree
class Dummy:
 extends Node2D
 var dead:=false
var checks: Array[String]=[]
var failures: Array[String]=[]
var emitted: Array=[]
var game: Node
var model: Node
func _initialize() -> void:call_deferred("run")
func check(ok: bool,message: String) -> void:
 if ok:checks.append(message)
 else:failures.append(message)
func record(slot: int,item: Dictionary,target: Node2D,cycle: Dictionary,context: Dictionary) -> void:
 emitted.append({"slot":slot,"item":item,"target":target,"run":cycle,"context":context})
func enemy(at: Vector2) -> Node2D:
 var e:=Dummy.new();e.position=at;game.enemies.add_child(e);return e
func finish(event: Dictionary,hit:=true,killed:=false) -> void:
 model.complete_skill(event.slot,event.target,{"position":event.context.aim,"hit":hit,"killed":killed,"critical":false,"element":event.item.key},event.run,event.context)
func reset() -> void:
 model.reset_runtime();emitted.clear()
 for e in game.enemies.get_children():e.free()
 model.load_kit();model.items[1].key="relay";model.items[4].level=3;model.items[6].level=3
 model.casts=0;model.hits=0;model.misses=0;model.jumps=0;model.empty_casts=0;model.retargets=0;model.trace.clear()
 model.clock=0;model.cooldown_until=0;model.resonance_chance=1.0;model.rolls=0;model.resonances=0;model.discovered=[]
func drain(hit:=false) -> void:
 for i in 20:
  for event in emitted.duplicate():finish(event,hit)
  emitted.clear();model.advance(0.33)
func run() -> void:
 game=load("res://experiments/chain_lab/main.tscn").instantiate();game.persist_book=false;root.add_child(game);current_scene=game
 game.set_process(false);game.set_physics_process(false);game.enemies.process_mode=Node.PROCESS_MODE_DISABLED
 model=game.chain;model.cast_requested.disconnect(game.cast_spell);model.resonance_requested.disconnect(game.resonate);model.cast_requested.connect(record)
 reset()
 var a:=enemy(game.CENTER);var b:=enemy(game.CENTER+Vector2(100,0));var c:=enemy(game.CENTER+Vector2(200,0));var d:=enemy(game.CENTER+Vector2(300,0));var e:=enemy(game.CENTER+Vector2(400,0))
 model.start(a);var root_cast: Dictionary=emitted.pop_front();finish(root_cast)
 model.advance(0.33);model.advance(0.33)
 check(emitted.size()==2,"fork emits two continuation spells")
 var fire: Dictionary=emitted[0];var ice: Dictionary=emitted[1]
 check(fire.target==b and ice.target==c and not a.dead,"living A jumps to living B and C without waiting for A to die")
 check(fire.target!=ice.target,"parallel branches reserve different unvisited enemies")
 check(fire.context.origin==a.position and ice.context.origin==a.position,"both branches originate at the preceding impact")
 emitted.clear();finish(ice);finish(fire);model.advance(0.33);model.advance(0.33)
 var origins: Dictionary={}
 for event in emitted:origins[event.slot]=event.context.origin
 check(origins[5]==c.position and origins[7]==b.position,"interleaved branch completions retain independent origins")
 check(emitted[0].target in [d,e] and emitted[1].target in [d,e] and emitted[0].target!=emitted[1].target,"later skills prefer remaining unvisited targets")
 drain(true);check(model.active.is_empty(),"all fork branches finish without stuck inflight count")
 reset();a=enemy(game.CENTER);model.start(a);finish(emitted.pop_front());a.free()
 model.advance(0.33);model.advance(0.33)
 check(emitted.size()==2 and emitted[0].target==null and emitted[1].target==null,"freed original target preserves both branches as empty casts")
 check(emitted[0].context.aim==game.CENTER,"empty cast retains last actual impact position")
 drain(false)
 check(model.misses>0 and model.active.is_empty(),"empty casts visibly settle and finish the round")
 check(model.resonances==1 and model.rolls==1,"empty actual casts can complete a cross-branch resonance exactly once")
 check(not model.start(null),"empty battlefield cannot create a fresh attack round")
 reset();a=enemy(game.CENTER);model.start(a);finish(emitted.pop_front(),false)
 model.advance(0.33);model.advance(0.33)
 check(emitted.size()==2,"cast-based relay can continue after a miss")
 reset();model.items[1].key="hit";a=enemy(game.CENTER);model.start(a);finish(emitted.pop_front(),false);model.advance(0.33)
 check(emitted.is_empty() and model.active.is_empty(),"miss cannot satisfy a hit gem")
 reset();model.items[1].key="kill";a=enemy(game.CENTER);model.start(a);finish(emitted.pop_front(),true,false);model.advance(0.33)
 check(emitted.is_empty() and model.active.is_empty(),"nonlethal hit cannot satisfy a kill gem")
 reset();model.items[1].key="kill";a=enemy(game.CENTER);model.start(a);finish(emitted.pop_front(),true,true);a.free();model.advance(0.33);model.advance(0.33)
 check(emitted.size()==2,"real kill can trigger a kill gem even when the dead target is freed")
 reset();model.items[1].key="crit";a=enemy(game.CENTER);model.start(a);finish(emitted.pop_front(),false);model.advance(0.33)
 check(emitted.is_empty(),"empty attack cannot fake a critical hit")
 reset();a=enemy(game.CENTER);model.start(a);finish(emitted.pop_front());a.free();model.advance(0.33)
 b=enemy(game.CENTER+Vector2(120,0));model.advance(0.33)
 check(emitted.size()==2 and emitted[0].target==b,"new enemy appearing between hops reconnects an empty continuation")
 reset();a=enemy(game.CENTER);model.start(a);finish(emitted.pop_front());a.free();b=enemy(game.CENTER+Vector2(900,0));model.advance(0.33);model.advance(0.33)
 check(emitted.size()==2 and emitted[0].target==null and emitted[1].target==null,"out-of-range enemies are not teleported into the chain")
 reset();a=enemy(game.CENTER);model.start(a);finish(emitted.pop_front());model.advance(0.33);model.advance(0.33)
 check(emitted.size()==2 and emitted[0].target==a and emitted[1].target==a,"lone living boss remains a valid repeat target")
 reset();a=enemy(game.CENTER);model.start(a);root_cast=emitted.pop_front();finish(root_cast);var pending_count: int=model.pending.size();finish(root_cast)
 check(model.pending.size()==pending_count,"duplicate impact callback cannot multiply continuation events")
 reset();a=enemy(game.CENTER);model.start(a);root_cast=emitted.pop_front();model.reset_runtime();model.start(a);finish(root_cast)
 check(model.active.inflight==1 and model.pending.is_empty(),"stale old-round impact cannot advance a replacement round")
 reset();a=enemy(game.CENTER);model.start(a)
 check(model.active.elements==["arcane"] and model.rolls==0,"only actually emitted skills provide elements, not unevaluated kit items")
 model.advance(0.10);check(model.active.elements==["arcane"],"waiting and untriggered nodes do not contribute resonance elements")
 # Actual renderer: free the enemy during flight, then require complete visible misses.
 model.cast_requested.disconnect(record);model.cast_requested.connect(game.cast_spell);model.resonance_requested.connect(game.resonate)
 reset();a=enemy(game.CENTER);model.start(a);a.free()
 for i in 360:
  model.advance(1.0/60.0)
  await physics_frame
 check(model.active.is_empty() and game.shots.get_child_count()==0,"real tweened projectiles finish empty chain after target is freed mid-flight")
 check(model.misses>=5,"real empty flight callbacks preserve every activated skill in the kit")
 check(model.resonances==1,"renderer-driven empty sequence records cast-based resonance")
 # No phantom damage or new roots during a natural empty-field pause.
 game.wave=1;game.remaining=0;game.rest=999;game.over=false;game.user_paused=false;game.edit_open=false
 var casts_before: int=model.casts
 for i in 30:game._physics_process(1.0/60.0);await physics_frame
 check(model.casts==casts_before,"director creates no auto attacks while battlefield is empty")
 var report={"engine":Engine.get_version_info().string,"checks":checks,"failures":failures,"counters":{"casts":model.casts,"hits":model.hits,"misses":model.misses,"jumps":model.jumps}}
 print("FLOW_RESULT "+JSON.stringify(report));paused=false;quit(0 if failures.is_empty() else 1)
