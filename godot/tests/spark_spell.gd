extends SceneTree
const Effects=preload("res://experiments/chain_lab/spell_effects.gd")
const Catalog=preload("res://modules/spell/catalog.gd")
const Enemy=preload("res://modules/enemy/enemy.gd")
var checks: Array=[]
var failures: Array=[]
var allocated: Array=[]
var resolver: Node
func check(ok: bool,message: String) -> void:
 if ok:checks.append(message)
 else:failures.append(message)
func _initialize() -> void:call_deferred("run")
func enemy(at: Vector2,parent: Node) -> Node2D:
 var e:=Enemy.new();e.max_hp=5000;e.hp=5000;e.speed=0;e.target=Vector2(9999,9999);e.position=at;parent.add_child(e);e.set_physics_process(false);allocated.append(e);return e
func clear() -> void:
 for e in allocated:
  if is_instance_valid(e):e.free()
 allocated=[]
func run() -> void:
 resolver=preload("res://modules/spell/combat_resolver.gd").new();root.add_child(resolver)
 check(Catalog.PLAYABLE.size()==8 and "spark" not in Catalog.PLAYABLE and Effects.PLAYABLE.size()==18 and Effects.PLAYABLE.slice(0,8)==Catalog.PLAYABLE,"spark is lab-only and stable root still advertises eight")
 check(Catalog.power("spark")==13 and Catalog.element("spark")=="lightning","spark retains source damage and lightning mapping")
 check(Effects.texture("spark").get_height()==192 and "火花術" in Effects.description("spark"),"spark has dedicated provisional plasma-flare sprite and explicit radius description")
 for level in range(1,4):
  var e:=enemy(Vector2(100,100),root);var result:=Effects.impact("spark",e,Vector2.ZERO,e.position,level,1.5,[e],resolver)
  check(result.hit_count==1 and is_equal_approx(5000-e.hp,13*(1+0.55*(level-1))*1.5),"level %d applies real level and meat scaling" % level);clear()
 var primary:=enemy(Vector2(100,100),root);enemy(Vector2(-64,100),root);enemy(Vector2(264,100),root);enemy(Vector2(100,264.9),root);var boundary:=enemy(Vector2(100,265),root)
 var row:=Effects.impact("spark",primary,Vector2.ZERO,primary.position,1,1,allocated,resolver)
 check(row.hit_count==4 and boundary.hp==5000,"ground radius includes inner victims and excludes exact one-hundred-sixty-five boundary")
 check(primary.slow_time==0 and primary.poison_time==0 and primary.position==Vector2(100,100),"spark adds no unsupported slow, poison or displacement")
 check(row.hit_positions.size()==4 and not row.hit_positions.has(boundary.position),"visual hit positions include only actual damaged victims")
 var rules=preload("res://experiments/chain_lab/gem_rules.gd")
 check(not rules.eligible("burn",row,3) and not rules.eligible("freeze",row,3),"lightning spark cannot invent fire or ice gem conditions")
 check(row.target_id==primary.get_instance_id() and row.element=="lightning","aggregate result identifies actual primary hit and element");clear()
 for i in range(25):enemy(Vector2(i,0),root)
 primary=enemy(Vector2(0,0),root);row=Effects.impact("spark",primary,Vector2.ZERO,primary.position,1,1,allocated,resolver)
 check(row.hit_count==6 and primary.hp==4987,"radius cap is six and selected target is retained")
 check(allocated.filter(func(e):return e.hp==4987).size()==6,"six real unique victims receive damage");clear()
 check(not Effects.impact("spark",null,Vector2.ZERO,Vector2.ZERO,1,1,[],resolver).hit,"empty ground produces no phantom hit")
 var game: Node=load("res://experiments/chain_lab/main.tscn").instantiate();game.persist_book=false;root.add_child(game);current_scene=game;game.set_process(false);game.set_physics_process(false)
 var model: Node=game.chain;model.items=[{"id":0,"kind":"skill","key":"arcane","level":1},{"id":1,"kind":"gem","key":"relay","level":3},{"id":2,"kind":"skill","key":"spark","level":2},{"id":3,"kind":"gem","key":"relay","level":3},{"id":4,"kind":"skill","key":"fire","level":1}];model.slots=[0,1,2,3,4,-1,-1,-1,-1,-1];model.edges=[{"from":0,"to":1},{"from":1,"to":2},{"from":2,"to":3},{"from":3,"to":4}];model.resonance_chance=0
 var first:=enemy(game.CENTER+Vector2(100,50),game.enemies);enemy(game.CENTER+Vector2(140,50),game.enemies);enemy(game.CENTER+Vector2(160,50),game.enemies);model.start(first);var first_run: Dictionary=model.active
 for i in range(240):model.advance(1.0/60.0);await process_frame
 check(game.spell_cast_counts.get("spark",0)==1 and game.spell_hit_counts.get("spark",0)==3,"real chain cast damages three ground targets")
 check("lightning" in first_run.elements,"real chain records lightning element without inventing a resonance recipe")
 check(game.spell_cast_counts.get("fire",0)==1 and model.active.is_empty(),"multi-victim spark advances its following gem exactly once");clear()
 model.reset_runtime();model.trace.clear();model.edges=[];model.slots.fill(-1);model.slots[0]=2
 first=enemy(game.CENTER+Vector2(140,50),game.enemies);var survivor:=enemy(game.CENTER+Vector2(180,50),game.enemies);var off_row:=enemy(game.CENTER+Vector2(500,300),game.enemies)
 model.start(first);first.free()
 for i in range(45):model.advance(1.0/60.0);await process_frame
 var strips: Array=game.fx.get_children().filter(func(node):return node.get_meta("spell_key","")=="spark")
 check(not strips.is_empty() and strips[0].get_child_count()==1 and strips[0].get_child(0).texture==Effects.SPARK_ART and is_equal_approx(strips[0].position.y,game.CENTER.y+50),"actual shaped hit-located burst FX uses dedicated artwork")
 check(not strips.is_empty() and strips[0].get_child(0).global_position.is_equal_approx(survivor.position),"burst Sprite is anchored to actual survivor hit location")
 for i in range(90):model.advance(1.0/60.0);await process_frame
 check(survivor.hp<5000 and off_row.hp==5000 and model.active.is_empty(),"freed initial target retains original ground point and rejects distant survivor")
 check(model.trace.any(func(event):return event.kind=="hit" and int(event.target)==survivor.get_instance_id()),"ground hit records the real survivor rather than target zero")
 model.reset_runtime();model.trace.clear();model.start(survivor);survivor.free()
 for i in range(120):model.advance(1.0/60.0);await process_frame
 check(model.active.is_empty() and model.trace.back().kind=="miss" and off_row.hp==5000,"freed target with no nearby victims finishes as an actual miss")
 clear()
 game.queue_free();await process_frame
 print("SPARK_RESULT "+JSON.stringify({"checks":checks,"failures":failures}));quit(0 if failures.is_empty() else 1)
