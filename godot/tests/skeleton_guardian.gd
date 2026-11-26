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
func summon_at(at: Vector2,level: int,boost: float) -> Node2D:return manager.summon_at(at,level,boost,"skeleton")
func run() -> void:
 resolver=preload("res://modules/spell/combat_resolver.gd").new();root.add_child(resolver)
 targets=Node2D.new();root.add_child(targets);manager=Manager.new();manager.targets=targets;manager.resolver=resolver;root.add_child(manager)
 check(Catalog.PLAYABLE.size()==8 and "skeleton" not in Catalog.PLAYABLE and Effects.PLAYABLE.size()==22,"summon is lab-only; stable root remains eight")
 check(Catalog.power("skeleton")==23 and Catalog.element("skeleton")=="skeleton","single-target summon retains source twenty-three power and class")
 check(Effects.texture("skeleton")==Effects.SKELETON_ART and "0.8" in Effects.description("skeleton"),"ghost has dedicated provisional art and autonomous cadence description")
 for level in range(1,4):
  var e:=enemy(Vector2.ZERO);var neighbor:=enemy(Vector2(10,0));var row:=Effects.impact("skeleton",e,Vector2.ZERO,e.position,level,1.5,allocated,resolver)
  check(row.hit_count==1 and is_equal_approx(5000-e.hp,23*(1+0.55*(level-1))*1.5) and neighbor.hp==5000,"tier %d is a real single-target direct hit" % level)
  var g: Node2D=summon_at(Vector2(24,-16),level,1.5);manager.advance(0.01)
  check(is_equal_approx(g.power,11*(1+0.55*(level-1))*1.5) and is_equal_approx(5000-e.hp,23*(1+0.55*(level-1))*1.5+g.power),"tier %d guardian deals captured level and blood-scaled real damage" % level)
  check(g.get_child_count()==3 and g.spirit.texture==Effects.SKELETON_ART and g.bolt.visible,"tier %d guardian has bounded spirit, seal and real-strike bolt Sprites" % level);clear()
 for level in range(1,4):
  for i in range(8):summon_at(Vector2.ZERO,level,1)
  check(manager.guards.size()==level+1,"tier %d repeated casts respect the live-guardian limit" % level)
  clear()
 check(summon_at(Vector2.ZERO,1,0)==null and summon_at(Vector2.ZERO,1,INF)==null,"invalid power cannot create a phantom guardian")
 var guard: Node2D=summon_at(Vector2(24,-16),1,1)
 var e:=enemy(Vector2(200,0));var start:=guard.position;var hits_before: int=manager.hits
 manager.advance(0.5)
 check(guard.intent=="追擊" and is_equal_approx(guard.position.distance_to(start),36.0) and e.hp==5000,"guardian actually moves seventy-two units per second before attacking")
 manager.advance(2.0)
 check(is_equal_approx(guard.position.distance_to(e.position),48.0) and e.hp==5000,"large movement step stops at melee reach without overshoot")
 manager.advance(0.01)
 check(e.hp==4989 and manager.hits==hits_before+1 and guard.cooldown==0.8,"real near-target strike resolves eleven damage and starts cooldown")
 manager.advance(0.79);check(e.hp==4989,"guardian cannot hit twice inside its cooldown")
 manager.advance(0.02);check(e.hp==4978,"guardian attacks again after the eight-tenths-second cadence")
 e.dead=true;var other:=enemy(guard.position+Vector2(30,0));manager.advance(0.81)
 check(other.hp==4989 and guard.target_id==other.get_instance_id(),"dead original target is discarded and a new living enemy is attacked")
 clear();guard=summon_at(Vector2(24,-16),1,1);e=enemy(Vector2(401,0));manager.advance(0.1)
 check(guard.position==Vector2.ZERO and guard.intent=="待命" and e.hp==5000,"out-of-sense targets are ignored without wandering")
 e.position=Vector2(400,0);manager.advance(0.1)
 check(guard.intent=="追擊" and guard.position.x>0,"sense boundary at four hundred is included")
 var life: float=guard.remaining;manager.advance(0);manager.advance(-1);manager.advance(INF)
 check(guard.remaining==life,"invalid or zero simulation deltas do not age guardians")
 manager.advance(8);await process_frame
 check(manager.guards.is_empty() and not is_instance_valid(guard),"expired guardians are removed and their nodes freed")
 check(summon_at(Vector2.ZERO,1,1)!=null,"expired slot permits another real summon");clear()
 guard=summon_at(Vector2(24,-16),1,1);e=enemy(Vector2(20,0));e.hp=1;e.max_hp=1;var kills_before: int=manager.kills;manager.advance(0.01)
 check(e.dead and manager.kills==kills_before+1,"guardian can deliver a real lethal strike");clear()
 var game: Node=load("res://experiments/chain_lab/main.tscn").instantiate();game.persist_book=false;game.persist_run=false;game.criticals_enabled=false;root.add_child(game);current_scene=game;game.set_process(false);game.set_physics_process(false)
 var model: Node=game.chain;model.resonance_chance=0;model.items=[{"id":0,"kind":"skill","key":"skeleton","level":1},{"id":1,"kind":"gem","key":"kill","level":3},{"id":2,"kind":"skill","key":"fire","level":1}];model.slots=[0,1,2,-1,-1,-1,-1,-1,-1,-1];model.edges=[{"from":0,"to":1},{"from":1,"to":2}]
 var real: Node2D=game.configure_enemy(Enemy.new(),false,game.CENTER+Vector2(120,30));real.hp=24;real.max_hp=24;real.set_physics_process(false)
 model.start(real)
 for i in range(90):model.advance(1.0/60.0);await process_frame
 check(real.hp==1 and game.spell_cast_counts.get("skeleton",0)==1 and game.spell_hit_counts.get("skeleton",0)==1,"actual summon projectile completes a real twenty-three-damage hit")
 check(model.active.is_empty() and game.spell_cast_counts.get("fire",0)==0,"nonlethal direct hit cannot pass the kill gem")
 check(game.guardians.guards.size()==1 and game.guardians.hits==0,"cast spawns a real guardian before any delayed strike")
 var meat_before: int=game.pending_flesh.size();game.guardians.advance(0.01)
 check(real.dead and game.guardians.kills==1 and game.pending_flesh.size()==meat_before+1,"guardian kill uses normal enemy death and flesh drop callback")
 for i in range(60):model.advance(1.0/60.0);await process_frame
 check(model.active.is_empty() and game.spell_cast_counts.get("fire",0)==0 and game.spell_hit_counts.get("skeleton",0)==1,"later guardian kill does not restart chain, pass a completed kill gem or inflate direct hit count")
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
 clear()
 var ghost: Node2D=manager.summon_at(Vector2(24,-16),3,1,"summon")
 var bone: Node2D=manager.summon_at(Vector2(24,-16),3,1,"skeleton")
 var ghost_before: int=manager.counts.summon.hits;var bone_before: int=manager.counts.skeleton.hits
 e=enemy(Vector2(60,0));manager.advance(0.01)
 check(manager.counts.summon.hits==ghost_before+1 and manager.counts.skeleton.hits==bone_before and bone.intent=="追擊","mixed units use different reach and independent strike metrics")
 check(ghost.bolt.texture==preload("res://experiments/chain_lab/assets/ghost_strike.tres") and bone.bolt.texture==preload("res://experiments/chain_lab/assets/bone_slash.svg") and not bone.bolt.texture is AtlasTexture,"mixed units use shared ghost crop versus the original skeleton slash without a skeleton atlas")
 check(ghost.spirit.texture==Effects.GHOST_ART and bone.spirit.texture==Effects.SKELETON_ART,"mixed summons keep distinct actual Sprite artwork")
 summon_at(Vector2.ZERO,3,1);manager.summon_at(Vector2.ZERO,3,1,"summon")
 check(manager.guards.size()==4 and summon_at(Vector2.ZERO,3,1)==null,"ghosts and skeletons share one four-unit global limit")
 check(manager.summon_at(Vector2.ZERO,1,1,"unknown")==null,"unknown guardian species fails closed")
 for species in ["summon","skeleton"]:
  var visual=preload("res://experiments/chain_lab/guardian_actor.gd").new();visual.species=species;root.add_child(visual)
  for row in [
   {"flash":0.0,"delta":0.016,"age":0.0,"life":8.0,"at":Vector2.ZERO,"aim":Vector2(40,20),"left":false,"intent":"待命"},
   {"flash":0.10,"delta":0.02,"age":0.35,"life":0.32,"at":Vector2(-20,12),"aim":Vector2(300,70),"left":true,"intent":"追擊"},
   {"flash":0.16,"delta":0.02,"age":1.2,"life":0.65,"at":Vector2(20,40),"aim":Vector2(20,40),"left":false,"intent":"攻擊"},
   {"flash":0.01,"delta":0.02,"age":2.0,"life":0.0,"at":Vector2(70,30),"aim":Vector2(-300,-70),"left":true,"intent":"待命"}]:
   check_legacy_pose(visual,row)
  visual.free()
 check(manager.snapshot().all(func(row):return row.type in ["summon","skeleton"]),"snapshot exposes truthful per-species actors")
 clear();manager.queue_free();targets.queue_free();resolver.queue_free();await process_frame
 print("SKELETON_RESULT "+JSON.stringify({"checks":checks,"failures":failures}));quit(0 if failures.is_empty() else 1)

func check_legacy_pose(actor: Node2D,row: Dictionary) -> void:
 # Frozen pre-optimization pose, including the old ghost calculation then override.
 actor.flash=row.flash;actor.age=row.age;actor.remaining=row.life;actor.position=row.at;actor.strike_point=row.aim;actor.facing_left=row.left;actor.intent=row.intent
 var flash: float=maxf(0.0,float(row.flash)-float(row.delta))
 var at: Vector2=actor.bolt.position;var angle: float=actor.bolt.rotation;var size: Vector2=actor.bolt.scale
 if flash>0:
  var offset: Vector2=row.aim-row.at
  at=offset*0.5+Vector2(0,-16);angle=offset.angle();size=Vector2(maxf(12,offset.length())/300.0,0.20)
  if actor.species=="skeleton":at=Vector2(-18 if row.left else 18,-22);angle=(-0.8+flash/0.14*1.6)*(-1 if row.left else 1);size=Vector2.ONE*0.65
 var bob: float=-30+(sin(row.age*9.0)*1.5 if actor.species=="skeleton" and row.intent=="追擊" else sin(row.age*3.5)*(1.0 if actor.species=="skeleton" else 4.0))
 var turn: float=sin(flash*22)*0.12 if actor.species=="skeleton" and flash>0 else 0.0
 actor.present(row.delta)
 check(actor.bolt.position.is_equal_approx(at) and is_equal_approx(actor.bolt.rotation,angle) and actor.bolt.scale.is_equal_approx(size) and actor.bolt.visible==(flash>0) and is_equal_approx(actor.spirit.position.y,bob) and is_equal_approx(actor.spirit.rotation,turn) and actor.spirit.flip_h==row.left and actor.spirit.modulate==(Color(1.3,1.6,1.8) if flash>0 else Color.WHITE) and is_equal_approx(actor.modulate.a,clampf(row.life/0.65,0,1)),"legacy pose preserved for %s, flash %.2f, age %.2f" % [actor.species,row.flash,row.age])
