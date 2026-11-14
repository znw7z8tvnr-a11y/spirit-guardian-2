extends SceneTree
const Effects=preload("res://experiments/chain_lab/spell_effects.gd")
const Catalog=preload("res://modules/spell/catalog.gd")
const Enemy=preload("res://modules/enemy/enemy.gd")
const Manager=preload("res://experiments/chain_lab/guardian_manager.gd")
var checks: Array=[]
var failures: Array=[]
var allocated: Array=[]
var resolver: Node
var targets: Node2D
var manager: Node2D
func check(ok: bool,message: String) -> void:
 if ok:checks.append(message)
 else:failures.append(message)
func _initialize() -> void:call_deferred("run")
func enemy(at: Vector2,parent: Node=targets) -> Node2D:
 var e:=Enemy.new();e.max_hp=5000;e.hp=5000;e.speed=0;e.position=at;e.target=Vector2(9999,9999);e.resolver=resolver;parent.add_child(e);e.set_physics_process(false);allocated.append(e);return e
func clear() -> void:
 for e in allocated:
  if is_instance_valid(e):e.free()
 allocated=[]
 for g in manager.get_children():g.free()
 manager.purge()
func run() -> void:
 resolver=preload("res://modules/spell/combat_resolver.gd").new();root.add_child(resolver)
 targets=Node2D.new();root.add_child(targets);manager=Manager.new();manager.targets=targets;manager.resolver=resolver;root.add_child(manager)
 check(Catalog.PLAYABLE.size()==8 and "summon" not in Catalog.PLAYABLE and Effects.PLAYABLE.size()==22,"summon is lab-only; stable root remains eight")
 check(Catalog.power("summon")==22 and Catalog.element("summon")=="summon","single-target summon retains source twenty-two power and class")
 check(Effects.texture("summon")==Effects.GHOST_ART and "0.55" in Effects.description("summon"),"ghost has dedicated provisional art and autonomous cadence description")
 for level in range(1,4):
  var e:=enemy(Vector2.ZERO);var neighbor:=enemy(Vector2(10,0));var row:=Effects.impact("summon",e,Vector2.ZERO,e.position,level,1.5,allocated,resolver)
  check(row.hit_count==1 and is_equal_approx(5000-e.hp,22*(1+0.55*(level-1))*1.5) and neighbor.hp==5000,"tier %d is a real single-target direct hit" % level)
  var g: Node2D=manager.summon_at(Vector2(24,-16),level,1.5);manager.advance(0.01)
  check(is_equal_approx(g.power,9*(1+0.55*(level-1))*1.5) and is_equal_approx(5000-e.hp,22*(1+0.55*(level-1))*1.5+g.power),"tier %d guardian deals captured level and blood-scaled real damage" % level)
  check(g.get_child_count()==3 and g.spirit.texture==Effects.GHOST_ART and g.bolt.visible,"tier %d guardian has bounded spirit, seal and real-strike bolt Sprites" % level);clear()
 for level in range(1,4):
  for i in range(8):manager.summon_at(Vector2.ZERO,level,1)
  check(manager.guards.size()==level+1,"tier %d repeated casts respect the live-guardian limit" % level)
  clear()
 check(manager.summon_at(Vector2.ZERO,1,0)==null and manager.summon_at(Vector2.ZERO,1,INF)==null,"invalid power cannot create a phantom guardian")
 var guard: Node2D=manager.summon_at(Vector2(24,-16),1,1)
 var e:=enemy(Vector2(200,0));var start:=guard.position;var hits_before: int=manager.hits
 manager.advance(0.5)
 check(guard.intent=="追擊" and is_equal_approx(guard.position.distance_to(start),44.0) and e.hp==5000,"guardian actually moves eighty-eight units per second before attacking")
 manager.advance(2.0)
 check(is_equal_approx(guard.position.distance_to(e.position),65.0) and e.hp==5000,"large movement step stops at melee reach without overshoot")
 manager.advance(0.01)
 check(e.hp==4991 and manager.hits==hits_before+1 and guard.cooldown==0.55,"real near-target strike resolves nine damage and starts cooldown")
 manager.advance(0.54);check(e.hp==4991,"guardian cannot hit twice inside its cooldown")
 manager.advance(0.02);check(e.hp==4982,"guardian attacks again after the half-second cadence")
 e.dead=true;var other:=enemy(guard.position+Vector2(30,0));manager.advance(0.56)
 check(other.hp==4991 and guard.target_id==other.get_instance_id(),"dead original target is discarded and a new living enemy is attacked")
 clear();guard=manager.summon_at(Vector2(24,-16),1,1);e=enemy(Vector2(401,0));manager.advance(0.1)
 check(guard.position==Vector2.ZERO and guard.intent=="待命" and e.hp==5000,"out-of-sense targets are ignored without wandering")
 e.position=Vector2(400,0);manager.advance(0.1)
 check(guard.intent=="追擊" and guard.position.x>0,"sense boundary at four hundred is included")
 var life: float=guard.remaining;manager.advance(0);manager.advance(-1);manager.advance(INF)
 check(guard.remaining==life,"invalid or zero simulation deltas do not age guardians")
 manager.advance(8);await process_frame
 check(manager.guards.is_empty() and not is_instance_valid(guard),"expired guardians are removed and their nodes freed")
 check(manager.summon_at(Vector2.ZERO,1,1)!=null,"expired slot permits another real summon");clear()
 guard=manager.summon_at(Vector2(24,-16),1,1);e=enemy(Vector2(20,0));e.hp=1;e.max_hp=1;var kills_before: int=manager.kills;manager.advance(0.01)
 check(e.dead and manager.kills==kills_before+1,"guardian can deliver a real lethal strike");clear()
 var game: Node=load("res://experiments/chain_lab/main.tscn").instantiate();game.persist_book=false;game.persist_run=false;game.criticals_enabled=false;root.add_child(game);current_scene=game;game.set_process(false);game.set_physics_process(false)
 var model: Node=game.chain;model.resonance_chance=0;model.items=[{"id":0,"kind":"skill","key":"summon","level":1},{"id":1,"kind":"gem","key":"kill","level":3},{"id":2,"kind":"skill","key":"fire","level":1}];model.slots=[0,1,2,-1,-1,-1,-1,-1,-1,-1];model.edges=[{"from":0,"to":1},{"from":1,"to":2}]
 var real: Node2D=game.configure_enemy(Enemy.new(),false,game.CENTER+Vector2(120,30));real.hp=23;real.max_hp=23;real.set_physics_process(false)
 model.start(real)
 for i in range(90):model.advance(1.0/60.0);await process_frame
 check(real.hp==1 and game.spell_cast_counts.get("summon",0)==1 and game.spell_hit_counts.get("summon",0)==1,"actual summon projectile completes a real twenty-two-damage hit")
 check(model.active.is_empty() and game.spell_cast_counts.get("fire",0)==0,"nonlethal direct hit cannot pass the kill gem")
 check(game.guardians.guards.size()==1 and game.guardians.hits==0,"cast spawns a real guardian before any delayed strike")
 var meat_before: int=game.pending_flesh.size();game.guardians.advance(0.01)
 check(real.dead and game.guardians.kills==1 and game.pending_flesh.size()==meat_before+1,"guardian kill uses normal enemy death and flesh drop callback")
 for i in range(60):model.advance(1.0/60.0);await process_frame
 check(model.active.is_empty() and game.spell_cast_counts.get("fire",0)==0 and game.spell_hit_counts.get("summon",0)==1,"later guardian kill does not restart chain, pass a completed kill gem or inflate direct hit count")
 var live_guard: Node=game.guardians.guards[0];life=live_guard.remaining
 game.user_paused=true;game._physics_process(0.5);check(live_guard.remaining==life,"pause freezes real guardian lifetime")
 game.user_paused=false;game.edit_open=true;game._physics_process(0.5);check(live_guard.remaining==life,"editing freezes real guardian lifetime")
 game.edit_open=false;game.growth_open=true;game._physics_process(0.5);check(live_guard.remaining==life,"growth panel freezes guardians")
 game.growth_open=false;game.rewards.pending=1;game._physics_process(0.5);check(live_guard.remaining==life,"pending reward freezes guardians")
 game.rewards.pending=0;game.over=true;game._physics_process(0.5);check(live_guard.remaining==life,"run end freezes guardian simulation")
 game.over=false;game.wave=1;game.remaining=0;game.rest=0.01;game.attack_clock=9999;game._physics_process(0.02)
 check(game.wave==2 and live_guard.remaining<life,"living guardian does not count as enemy or prevent next wave")
 for g in game.guardians.get_children():g.free()
 game.guardians.purge();model.reset_runtime();model.trace.clear();model.slots.fill(-1);model.slots[0]=0;model.edges=[]
 real=game.configure_enemy(Enemy.new(),false,game.CENTER+Vector2(140,50));real.set_physics_process(false);model.start(real);real.free()
 var spawn_before: int=game.guardians.spawns
 for i in range(100):model.advance(1.0/60.0);await process_frame
 check(model.active.is_empty() and model.trace.back().kind=="miss" and game.guardians.spawns==spawn_before+1,"empty retarget keeps a harmless summon at original aim while direct chain reports a miss")
 live_guard=game.guardians.guards[0];start=live_guard.position;game.guardians.advance(1)
 check(live_guard.position==start and live_guard.intent=="待命","empty-ground guardian remains harmless without targets")
 game.queue_free();await process_frame
 check(not is_instance_valid(live_guard),"scene teardown frees autonomous guardians")
 clear();manager.queue_free();targets.queue_free();resolver.queue_free();await process_frame
 print("GUARDIAN_RESULT "+JSON.stringify({"checks":checks,"failures":failures}));quit(0 if failures.is_empty() else 1)
