extends SceneTree
const Effects=preload("res://experiments/chain_lab/spell_effects.gd")
const Enemy=preload("res://modules/enemy/enemy.gd")
const Resolver=preload("res://modules/spell/combat_resolver.gd")
const Catalog=preload("res://modules/spell/catalog.gd")
var checks: Array=[]
var failures: Array=[]
var resolver: Node
var allocated: Array=[]
func check(ok: bool,message: String) -> void:
 if ok:checks.append(message)
 else:failures.append(message)
func enemy(at: Vector2, health:=5000.0) -> Node2D:
 var e:=Enemy.new();e.position=at;e.target=Vector2(9999,9999);e.max_hp=health;e.hp=health;e.speed=0;e.resolver=resolver;root.add_child(e);e.set_physics_process(false);allocated.append(e);return e
func clear() -> void:
 for e in allocated:
  if is_instance_valid(e):e.free()
 allocated=[]
func _initialize() -> void:call_deferred("run")
func run() -> void:
 resolver=Resolver.new();root.add_child(resolver)
 for key in Catalog.PLAYABLE:
  var e:=enemy(Vector2.ZERO)
  var result:=Effects.impact(key,e,Vector2(-100,0),e.position,3,1.5,[e],resolver)
  check(result.hit and result.hit_count==1 and is_equal_approx(result.damage,Catalog.power(key)*2.1*1.5),"%s applies actual level-three meat-scaled damage" % key)
  check(Effects.texture(key)!=null and Effects.description(key)!="尚未實作","%s has an explicit visual and behavior description" % key);clear()
 check(Effects.texture("meteor") is AtlasTexture and Effects.texture("meteor").get_height()==94 and Effects.texture("poison").get_width()==190,"lab uses bounded atlas regions instead of displaying mixed legacy sheets")
 var poison:=enemy(Vector2.ZERO);Effects.impact("poison",poison,Vector2(-100,0),Vector2.ZERO,1,1,[poison],resolver)
 for i in range(5):poison._physics_process(0.5)
 check(is_equal_approx(poison.hp,5000-17-15) and poison.poison_time==0,"poison produces five real ticks and expires without refreshing itself");clear()
 var primary:=enemy(Vector2.ZERO,5);var near:=enemy(Vector2(144,0),5);var far:=enemy(Vector2(146,0))
 var meteor:=Effects.impact("meteor",primary,Vector2(-100,0),Vector2.ZERO,1,1,allocated,resolver)
 check(meteor.hit_count==2 and meteor.killed and far.hp==5000,"meteor damages and kills actual targets inside 145 only");clear()
 for i in range(26):enemy(Vector2(i,0))
 var capped:=Effects.impact("meteor",allocated[0],Vector2(-100,0),Vector2.ZERO,1,1,allocated,resolver)
 check(capped.hit_count==24,"meteor target count is bounded at twenty-four");clear()
 primary=enemy(Vector2.ZERO);near=enemy(Vector2(75,0));far=enemy(Vector2(76,0))
 var nova:=Effects.impact("nova",primary,Vector2(-100,0),Vector2.ZERO,1,1,allocated,resolver)
 check(nova.hit_count==2 and near.slow_time==1.8 and far.hp==5000 and far.slow_time==0,"nova uses V9 radius seventy-five and real ice slow");clear()
 primary=enemy(Vector2(100,0));near=enemy(Vector2(220,10));enemy(Vector2(-10,0));enemy(Vector2(100,29));enemy(Vector2(261,0))
 var beam:=Effects.impact("beam",primary,Vector2.ZERO,primary.position,1,1,allocated,resolver)
 check(beam.hit_count==2 and near.hp==4970 and allocated[2].hp==5000 and allocated[3].hp==5000 and allocated[4].hp==5000,"beam pierces its finite forward path and rejects off-axis or out-of-range targets");clear()
 for i in range(10):enemy(Vector2(10+i*10,0))
 primary=enemy(Vector2(200,0));beam=Effects.impact("beam",primary,Vector2.ZERO,primary.position,1,1,allocated,resolver)
 check(beam.hit_count==8 and primary.hp==4970,"beam cap includes the actual selected target");clear()
 primary=enemy(Vector2.ZERO);near=enemy(Vector2(10,0));Effects.impact("fire",primary,Vector2(-100,0),primary.position,3,2,allocated,resolver)
 check(is_equal_approx(5000-near.hp,24*2.1*2*0.45),"existing fire splash now uses the same level and meat formula as direct hits");clear()
 near=enemy(Vector2(10,0));nova=Effects.impact("nova",null,Vector2(-100,0),Vector2.ZERO,1,1,allocated,resolver)
 check(nova.hit and nova.target_id==near.get_instance_id(),"ground-centered area hit identifies a real target for chain gates");clear()
 check(not Effects.impact("beam",null,Vector2.ZERO,Vector2(100,0),1,1,[],resolver).hit,"empty beam remains a visible miss without phantom hits")
 check(not Effects.impact("skeleton",null,Vector2.ZERO,Vector2.ZERO,1,1,[],resolver).hit,"unported skill cannot masquerade as working damage")
 var rewards=load("res://experiments/chain_lab/rewards.gd").new();rewards.rng.seed=1001;var seen: Array=[]
 for i in range(300):
  rewards.roll()
  for offer in rewards.offers:
   if offer.kind=="skill" and offer.key not in seen:seen.append(offer.key)
 check(seen.size()==9,"normal reward pool can produce all nine lab spell types");rewards.free()
 var game=load("res://experiments/chain_lab/main.tscn").instantiate();game.persist_book=false;root.add_child(game);current_scene=game;game.set_physics_process(false)
 game.chain.load_spell_kit();game.chain.rng.seed=32012;game.chain.resonance_chance=0
 var count: int=game.chain.items.size();game.chain.load_spell_kit()
 check(count==19 and game.chain.items.size()==19 and game.chain.slots.count(-1)==1,"spell training kit is idempotent and keeps nine used slots within capacity ten")
 for i in range(6):
  var e:=Enemy.new();e.max_hp=5000;e.hp=5000;e.speed=0;e.position=game.CENTER+Vector2(140+(i%3)*35,(i/3)*40);e.target=game.CENTER;e.resolver=game.resolver;game.enemies.add_child(e)
 game.chain.start(game.enemies.get_child(0))
 for i in range(600):
  game.chain.advance(1.0/60);await physics_frame
  if game.chain.active.is_empty():break
 for key in ["poison","meteor","nova","beam"]:
  check(int(game.spell_cast_counts.get(key,0))>=1 and int(game.spell_hit_counts.get(key,0))>=1,"real chained %s projectile completes with actual hits" % key)
 check(game.chain.active.is_empty() and game.shots.get_child_count()==0 and game.fx.get_child_count()<=48,"new spell flights complete once and keep visual bounds")
 var trace_valid:=true
 for event in game.chain.trace:
  if event.kind=="hit" and event.target==0:trace_valid=false
 check(trace_valid,"multi-target casts never record a phantom hit on target zero")
 for e in game.enemies.get_children():e.free()
 game.chain.reset_runtime();game.chain.edges=[];game.chain.slots.fill(-1);game.chain.slots[0]=game.chain.spell_kit_ids.meteor
 var doomed:=Enemy.new();doomed.position=game.CENTER+Vector2(180,0);doomed.hp=5000;doomed.max_hp=5000;doomed.speed=0;doomed.resolver=game.resolver;game.enemies.add_child(doomed)
 var survivor:=Enemy.new();survivor.position=doomed.position+Vector2(100,0);survivor.hp=5000;survivor.max_hp=5000;survivor.speed=0;survivor.resolver=game.resolver;game.enemies.add_child(survivor)
 game.chain.start(doomed);doomed.free()
 for i in range(240):
  game.chain.advance(1.0/60);await physics_frame
  if game.chain.active.is_empty():break
 check(survivor.hp<5000,"meteor retains its ground impact when its initial target is freed during flight")
 check(game.chain.trace.back().kind=="hit" and game.chain.trace.back().target==survivor.get_instance_id(),"renderer records the actual area victim instead of a phantom target")
 game.queue_free();resolver.queue_free();await process_frame
 print("EIGHTSPELLS_RESULT "+JSON.stringify({"checks":checks,"failures":failures}));quit(1 if failures.size() else 0)
