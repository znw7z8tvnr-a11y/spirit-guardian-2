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
 check(Catalog.PLAYABLE.size()==8 and "thorn" not in Catalog.PLAYABLE and Effects.PLAYABLE.size()==22 and Effects.PLAYABLE.slice(0,8)==Catalog.PLAYABLE,"thorn is lab-only and stable root still advertises eight")
 check(Catalog.power("thorn")==20 and Catalog.element("thorn")=="thorn","thorn retains source damage and thorn identity")
 check(Effects.texture("thorn").get_height()==192 and "荊棘護城" in Effects.description("thorn"),"thorn has dedicated provisional vortex sprite and explicit radius description")
 for level in range(1,4):
  var e:=enemy(Vector2(100,100),root);var result:=Effects.impact("thorn",e,Vector2.ZERO,e.position,level,1.5,[e],resolver)
  check(result.hit_count==1 and is_equal_approx(5000-e.hp,20*(1+0.55*(level-1))*1.5),"level %d applies real level and meat scaling" % level);clear()
 var primary:=enemy(Vector2(100,100),root);enemy(Vector2(26,100),root);enemy(Vector2(174,100),root);enemy(Vector2(100,174.9),root);var boundary:=enemy(Vector2(100,175),root)
 var row:=Effects.impact("thorn",primary,Vector2.ZERO,primary.position,1,1,allocated,resolver)
 check(row.hit_count==4 and boundary.hp==5000,"ground radius includes inner victims and excludes exact seventy-five boundary")
 check(primary.slow_time==0 and primary.poison_time==0 and primary.position==Vector2(100,100),"thorn adds no unsupported slow, poison or displacement")
 check(row.target_id==primary.get_instance_id() and row.element=="thorn","aggregate result identifies actual primary hit and element");clear()
 for i in range(25):enemy(Vector2(i,0),root)
 primary=enemy(Vector2(0,0),root);row=Effects.impact("thorn",primary,Vector2.ZERO,primary.position,1,1,allocated,resolver)
 check(row.hit_count==24 and primary.hp==4980,"radius cap is twenty-four and selected target is retained")
 check(allocated.filter(func(e):return e.hp==4980).size()==24,"twenty-four real unique victims receive damage");clear()
 check(not Effects.impact("thorn",null,Vector2.ZERO,Vector2.ZERO,1,1,[],resolver).hit,"empty ground produces no phantom hit")
 var game: Node=load("res://experiments/chain_lab/main.tscn").instantiate();game.persist_book=false;game.persist_run=false;game.criticals_enabled=false;root.add_child(game);current_scene=game;game.set_process(false);game.set_physics_process(false)
 var hit_points: Array=[]
 for i in range(24):hit_points.append(Vector2(i*3,0))
 game.spell_visual("thorn",Vector2.ZERO,Vector2.ZERO,hit_points)
 var bounded: Node=game.fx.get_child(game.fx.get_child_count()-1)
 check(bounded.get_child_count()==9,"twenty-four real hits create one root bed and exactly eight bounded thorn Sprites")
 check(bounded.get_children().slice(1).all(func(n):return n.texture==Effects.THORN_SPIKE),"all eight thorn Sprites use dedicated temporary artwork")
 bounded.free();game.spell_visual("thorn",Vector2.ZERO,game.CENTER,[])
 bounded=game.fx.get_child(game.fx.get_child_count()-1)
 check(bounded.get_child_count()==9 and bounded.position==game.CENTER,"empty cast still renders harmless thorn at original aim")
 bounded.free()
 var model: Node=game.chain;model.items=[{"id":0,"kind":"skill","key":"arcane","level":1},{"id":1,"kind":"gem","key":"relay","level":3},{"id":2,"kind":"skill","key":"thorn","level":2},{"id":3,"kind":"gem","key":"relay","level":3},{"id":4,"kind":"skill","key":"fire","level":1}];model.slots=[0,1,2,3,4,-1,-1,-1,-1,-1];model.edges=[{"from":0,"to":1},{"from":1,"to":2},{"from":2,"to":3},{"from":3,"to":4}];model.resonance_chance=0
 var first:=enemy(game.CENTER+Vector2(100,50),game.enemies);enemy(game.CENTER+Vector2(140,50),game.enemies);enemy(game.CENTER+Vector2(160,50),game.enemies);model.start(first);var first_run: Dictionary=model.active
 for i in range(240):model.advance(1.0/60.0);await process_frame
 check(game.spell_cast_counts.get("thorn",0)==1 and game.spell_hit_counts.get("thorn",0)==3,"real chain cast damages three ground targets")
 check("thorn" in first_run.elements,"real chain records thorn identity without inventing a resonance recipe")
 check(game.spell_cast_counts.get("fire",0)==1 and model.active.is_empty(),"multi-victim thorn advances its following gem exactly once");clear()
 model.reset_runtime();model.trace.clear();model.edges=[];model.slots.fill(-1);model.slots[0]=2
 first=enemy(game.CENTER+Vector2(140,50),game.enemies);var survivor:=enemy(game.CENTER+Vector2(180,50),game.enemies);var off_row:=enemy(game.CENTER+Vector2(300,150),game.enemies)
 model.start(first);first.free()
 for i in range(45):model.advance(1.0/60.0);await process_frame
 var strips: Array=game.fx.get_children().filter(func(node):return node.get_meta("spell_key","")=="thorn")
 check(not strips.is_empty() and strips[0].get_child(0).texture==Effects.THORN_ART and strips[0].get_child(1).scale.y>0.1 and is_equal_approx(strips[0].position.y,game.CENTER.y+50),"actual shaped thorn FX grows dedicated spike artwork")
 check(not strips.is_empty() and strips[0].get_child_count()==9 and strips[0].position==game.CENTER+Vector2(140,50),"eight thorn Sprites remain centered on the retained cast point")
 var thorn_fx: Node=strips[0];thorn_fx.set_process(false);var previous_height: float=thorn_fx.get_child(1).scale.y;thorn_fx._process(0.1)
 check(thorn_fx.get_child(1).scale.y!=previous_height and thorn_fx.get_child(1).position.length()<=62.0,"thorn growth changes Sprite height while staying inside the bounded ground footprint")
 thorn_fx._process(1.0);await process_frame
 check(not is_instance_valid(thorn_fx),"finite thorn effect frees itself after its lifetime")
 var once_hp: float=survivor.hp
 for i in range(90):model.advance(1.0/60.0);await process_frame
 check(survivor.hp==once_hp and survivor.position==game.CENTER+Vector2(180,50),"visual thorn causes neither repeated damage nor enemy displacement")
 check(survivor.hp<5000 and off_row.hp==5000 and model.active.is_empty(),"freed initial target retains original ground point and rejects distant survivor")
 check(model.trace.any(func(event):return event.kind=="hit" and int(event.target)==survivor.get_instance_id()),"ground hit records the real survivor rather than target zero")
 model.reset_runtime();model.trace.clear();model.start(survivor);survivor.free()
 for i in range(120):model.advance(1.0/60.0);await process_frame
 check(model.active.is_empty() and model.trace.back().kind=="miss" and off_row.hp==5000,"freed target with no nearby victims finishes as an actual miss")
 clear()
 game.queue_free();await process_frame
 print("THORN_RESULT "+JSON.stringify({"checks":checks,"failures":failures}));quit(0 if failures.is_empty() else 1)
