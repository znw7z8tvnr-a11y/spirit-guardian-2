extends SceneTree
const Rules=preload("res://experiments/chain_lab/gem_rules.gd")
const Catalog=preload("res://modules/spell/catalog.gd")
const Enemy=preload("res://modules/enemy/enemy.gd")
const SOURCE_ATTACK=["blast","bolt","venom","frostatk","critical","piercing","range","multi"]
var checks: Array=[]
var failures: Array=[]
var game: Node
var model: Node
var allocated: Array=[]
var impacts: Array=[]
func check(ok: bool,message: String) -> void:
 if ok:checks.append(message)
 else:failures.append(message)
func _initialize() -> void:call_deferred("run")
func enemy(at: Vector2) -> Node2D:
 var e:=Enemy.new();e.max_hp=5000;e.hp=5000;e.speed=0;e.target=Vector2(9999,9999);e.position=at;e.resolver=game.resolver;game.enemies.add_child(e);e.set_physics_process(false);allocated.append(e);return e
func configure(items: Array) -> void:
 model.reset_runtime();model.items=items;model.slots.fill(-1);model.edges=[];model.resonance_chance=0
 for i in items.size():
  model.slots[i]=i
  if i>0:model.edges.append({"from":i-1,"to":i})
 impacts=[];model.trace.clear()
func settle() -> void:
 for i in range(360):
  model.advance(1.0/60.0);await process_frame
  if model.active.is_empty():break
func clear() -> void:
 model.reset_runtime()
 for e in allocated:
  if is_instance_valid(e):e.free()
 allocated=[]
 for node in game.fx.get_children():node.free()
 for node in game.guardians.get_children():node.free()
 game.guardians.purge()
func run() -> void:
 game=load("res://experiments/chain_lab/main.tscn").instantiate();game.persist_book=false;game.criticals_enabled=false;root.add_child(game);current_scene=game;game.set_process(false);game.set_physics_process(false);model=game.chain
 game.resolver.hit_resolved.connect(func(e,result,context):impacts.append({"damage":float(result.damage),"key":str(context.get("spell_key","")),"tick":bool(context.get("status_tick",false))}))
 check(Rules.KEYS.size()==20 and Rules.ATTACK_BONUSES.size()==8,"all nineteen original gems plus one prototype relay")
 var expression:=RegEx.new();expression.compile("(\\d+)%")
 for key in SOURCE_ATTACK:
  var source_values:=expression.search_all(str(Catalog.data.GEM[key][2]))
  check(source_values.size()==3 and Rules.title(key)==Catalog.data.GEM[key][1],key+" source description and display identity retained")
  check(Rules.texture(key)==Rules.ATTACK_ART and Rules.texture("relay")!=Rules.ATTACK_ART,key+" has distinct temporary attack-gem artwork")
  for level in range(1,4):
   var scale:=1+float(source_values[level-1].get_string(1))/100.0
   configure([{"id":0,"kind":"skill","key":"arcane","level":1},{"id":1,"kind":"gem","key":key,"level":level},{"id":2,"kind":"skill","key":"fire","level":1},{"id":3,"kind":"gem","key":"relay","level":3},{"id":4,"kind":"skill","key":"ice","level":1}])
   var e:=enemy(game.CENTER+Vector2(100,0));model.start(e);await settle()
   check(is_equal_approx(5000-e.hp,18*scale+24+21) and impacts.size()==3,"%s tier %d modifies real preceding damage exactly once" % [key,level])
   check(impacts.size()==3 and is_equal_approx(impacts[0].damage,18*scale) and is_equal_approx(impacts[1].damage,24) and is_equal_approx(impacts[2].damage,21),"%s tier %d never leaks its bonus into later real hits" % [key,level])
   check(model.active.is_empty() and Rules.branch_limit(key,level)==1 and Rules.eligible(key,{"hit":false},level) and Rules.next_multiplier(key,level)==1,"%s tier %d has one reliable continuation and no next-skill multiplier" % [key,level]);clear()
 check(Rules.branch_limit("relay",3)==2,"level-three conditional gem still permits the existing fork")
 configure([{"id":0,"kind":"skill","key":"arcane","level":1},{"id":1,"kind":"gem","key":"critical","level":3},{"id":2,"kind":"skill","key":"fire","level":1},{"id":3,"kind":"skill","key":"ice","level":1}]);model.edges=[{"from":0,"to":1},{"from":1,"to":2}]
 check(not model.connect_slots(1,3),"level-three attack gem cannot open a second branch")
 model.items[1].key="relay";check(model.connect_slots(1,3),"replacing the rule with level-three relay allows its second branch")
 model.items.append({"id":4,"kind":"gem","key":"critical","level":3});var slots_before: Array=model.slots.duplicate();var edges_before: Array=model.edges.duplicate(true)
 check(not model.equipment_error(1,4).is_empty() and not model.equip(1,4) and model.slots==slots_before and model.edges==edges_before,"forked conditional gem cannot be replaced by a single-line attack gem without removing the extra edge")
 configure([{"id":0,"kind":"skill","key":"arcane","level":1},{"id":1,"kind":"gem","key":"split","level":3},{"id":2,"kind":"skill","key":"fire","level":1},{"id":3,"kind":"gem","key":"blast","level":3},{"id":4,"kind":"skill","key":"ice","level":1}])
 var e:=enemy(game.CENTER+Vector2(100,0));model.start(e);await settle()
 check(impacts.size()==3 and is_equal_approx(impacts[1].damage,24*1.35*1.5) and is_equal_approx(impacts[2].damage,21),"incoming next-skill and local preceding-gem scales multiply without leaking to the next node");clear()
 configure([{"id":0,"kind":"skill","key":"arcane","level":3},{"id":1,"kind":"gem","key":"critical","level":3},{"id":2,"kind":"skill","key":"fire","level":1}]);game.tower.levels.atk=2;game.rewards.attack_stacks=1
 e=enemy(game.CENTER+Vector2(100,0));model.start(e);await settle()
 check(impacts.size()==2 and is_equal_approx(impacts[0].damage,18*2.1*2.0*1.1*1.7) and is_equal_approx(impacts[1].damage,24*2.0*1.1),"skill tier, blood and affix scaling compose with the new local gem bonus")
 game.tower.levels.atk=0;game.rewards.attack_stacks=0;clear()
 configure([{"id":0,"kind":"skill","key":"fire","level":1},{"id":1,"kind":"gem","key":"blast","level":3},{"id":2,"kind":"skill","key":"ice","level":1}])
 e=enemy(game.CENTER+Vector2(100,0));model.serial+=1;model.active={"id":model.serial,"events":0,"elements":[],"checked":false,"inflight":0,"visited":[]}
 # Guaranteed repeat only in this native fixture, without changing gameplay chances.
 model.emit_skill(0,e,model.active,{"origin":game.CENTER,"aim":e.position,"previous_id":0,"damage_scale":1.0,"echo_chance":1.0});await settle()
 var fire_hits:=impacts.filter(func(row):return row.key=="fire")
 check(fire_hits.size()==2 and fire_hits.all(func(row):return is_equal_approx(row.damage,36)) and impacts.filter(func(row):return row.key=="ice").size()==1,"echo reapplies one local bonus per impact without squaring it or repeating downstream traversal");clear()
 configure([{"id":0,"kind":"skill","key":"poison","level":1},{"id":1,"kind":"gem","key":"blast","level":3}]);e=enemy(game.CENTER+Vector2(100,0));model.start(e);await settle();var after_direct: float=e.hp
 for tick in range(5):e._physics_process(0.5)
 check(is_equal_approx(5000-after_direct,17*1.5) and is_equal_approx(after_direct-e.hp,15),"new preceding direct bonus never scales poison ticks");clear()
 for kind in ["summon","skeleton"]:
  configure([{"id":0,"kind":"skill","key":kind,"level":1},{"id":1,"kind":"gem","key":"critical","level":3}]);e=enemy(game.CENTER+Vector2(100,0));model.start(e);await settle()
  check(is_equal_approx(5000-e.hp,Catalog.power(kind)*1.7) and game.guardians.guards.size()==1 and is_equal_approx(game.guardians.guards[0].power,9 if kind=="summon" else 11),kind+" direct hit is boosted while its later autonomous power remains unchanged");clear()
 configure([{"id":0,"kind":"skill","key":"arcane","level":1},{"id":1,"kind":"gem","key":"range","level":3},{"id":2,"kind":"skill","key":"fire","level":1}]);e=enemy(game.CENTER+Vector2(100,0));model.start(e);e.free();await settle()
 check(model.active.is_empty() and model.trace.filter(func(row):return row.kind=="miss").size()==2,"miss still evaluates the attack gem and finishes remaining empty cast without phantom hit");clear()
 configure([{"id":0,"kind":"skill","key":"meteor","level":1},{"id":1,"kind":"gem","key":"range","level":3}]);e=enemy(game.CENTER+Vector2(100,0));var outside:=enemy(e.position+Vector2(146,0));model.start(e);await settle()
 check(is_equal_approx(5000-e.hp,44*1.35) and outside.hp==5000,"range gem retains source damage-only behavior and does not expand meteor radius");clear()
 model.kit_loaded=false;model.spell_kit_loaded=false;model.attack_kit_loaded=false;model.items=[{"id":0,"kind":"skill","key":"arcane","level":1}];model.kit_ids=[];model.gem_kit_ids={};model.spell_kit_ids={}
 model.load_attack_gem_kit();var owned: Array=model.items.duplicate(true);model.load_attack_gem_kit()
 check(model.items.size()==40 and model.items==owned and model.slots.count(-1)==1,"attack training grants all eight once and preserves nine-slot fixture")
 check(SOURCE_ATTACK.all(func(key):return model.gem_kit_ids.has(key)),"all eight owned attack gems are addressable by physical inventory id")
 game.inventory.open(model,0,1.0)
 check("30.6" in game.inventory.detail.text and "70%" in game.inventory.detail.text,"skill comparison previews current preceding attack-gem damage")
 game.inventory.show_page(2)
 check(game.inventory.entries.get_children().filter(func(n):return n.visible).size()==11 and game.inventory.cards["Item 39"].visible,"third page exposes final new item without discarding the old inventory")
 game.inventory.hide();model.reset_runtime();e=enemy(game.CENTER+Vector2(100,0));impacts=[];model.start(e);await settle()
 var expected: Array=[18*1.7,24*1.5,21*1.55*1.35,20*1.45,18*1.55]
 check(impacts.size()==5 and range(5).all(func(i):return is_equal_approx(impacts[i].damage,expected[i])),"real attack training projectiles use five distinct local modifiers with no carryover")
 clear();game.queue_free();await process_frame
 print("ATTACKGEMS_RESULT "+JSON.stringify({"checks":checks,"failures":failures}));quit(0 if failures.is_empty() else 1)
