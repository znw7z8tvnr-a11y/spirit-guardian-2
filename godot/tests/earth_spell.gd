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
 check(Catalog.PLAYABLE.size()==8 and "earth" not in Catalog.PLAYABLE and Effects.PLAYABLE.size()==11 and Effects.PLAYABLE.slice(0,8)==Catalog.PLAYABLE,"earth is lab-only and stable root still advertises eight")
 check(Catalog.power("earth")==29 and Catalog.element("earth")=="earth","earth retains source damage and earth mapping")
 check(Effects.texture("earth").get_height()==192 and "土刺" in Effects.description("earth"),"earth has dedicated provisional rock sprite and explicit radius description")
 for level in range(1,4):
  var e:=enemy(Vector2(100,100),root);var result:=Effects.impact("earth",e,Vector2.ZERO,e.position,level,1.5,[e],resolver)
  check(result.hit_count==1 and is_equal_approx(5000-e.hp,29*(1+0.55*(level-1))*1.5),"level %d applies real level and meat scaling" % level);clear()
 var primary:=enemy(Vector2(100,100),root);enemy(Vector2(26,100),root);enemy(Vector2(174,100),root);enemy(Vector2(100,174.9),root);var boundary:=enemy(Vector2(100,175),root)
 var row:=Effects.impact("earth",primary,Vector2.ZERO,primary.position,1,1,allocated,resolver)
 check(row.hit_count==4 and boundary.hp==5000,"ground radius includes inner victims and excludes exact seventy-five boundary")
 check(row.target_id==primary.get_instance_id() and row.element=="earth","aggregate result identifies actual primary hit and element");clear()
 for i in range(25):enemy(Vector2(i,0),root)
 primary=enemy(Vector2(0,0),root);row=Effects.impact("earth",primary,Vector2.ZERO,primary.position,1,1,allocated,resolver)
 check(row.hit_count==24 and primary.hp==4971,"radius cap is twenty-four and selected target is retained")
 check(allocated.filter(func(e):return e.hp==4971).size()==24,"twenty-four real unique victims receive damage");clear()
 check(not Effects.impact("earth",null,Vector2.ZERO,Vector2.ZERO,1,1,[],resolver).hit,"empty ground produces no phantom hit")
 var game: Node=load("res://experiments/chain_lab/main.tscn").instantiate();game.persist_book=false;root.add_child(game);current_scene=game;game.set_process(false);game.set_physics_process(false)
 var model: Node=game.chain;model.items=[{"id":0,"kind":"skill","key":"arcane","level":1},{"id":1,"kind":"gem","key":"relay","level":3},{"id":2,"kind":"skill","key":"earth","level":2},{"id":3,"kind":"gem","key":"relay","level":3},{"id":4,"kind":"skill","key":"fire","level":1}];model.slots=[0,1,2,3,4,-1,-1,-1,-1,-1];model.edges=[{"from":0,"to":1},{"from":1,"to":2},{"from":2,"to":3},{"from":3,"to":4}];model.resonance_chance=0
 var first:=enemy(game.CENTER+Vector2(100,50),game.enemies);enemy(game.CENTER+Vector2(140,50),game.enemies);enemy(game.CENTER+Vector2(160,50),game.enemies);model.start(first)
 for i in range(240):model.advance(1.0/60.0);await process_frame
 check(game.spell_cast_counts.get("earth",0)==1 and game.spell_hit_counts.get("earth",0)==3,"real chain cast damages three ground targets")
 check(game.spell_cast_counts.get("fire",0)==1 and model.active.is_empty(),"multi-victim earth advances its following gem exactly once");clear()
 model.reset_runtime();model.trace.clear();model.edges=[];model.slots.fill(-1);model.slots[0]=2
 first=enemy(game.CENTER+Vector2(140,50),game.enemies);var survivor:=enemy(game.CENTER+Vector2(180,50),game.enemies);var off_row:=enemy(game.CENTER+Vector2(300,150),game.enemies)
 model.start(first);first.free()
 for i in range(45):model.advance(1.0/60.0);await process_frame
 var strips: Array=game.fx.get_children().filter(func(node):return node.get_meta("spell_key","")=="earth")
 check(not strips.is_empty() and strips[0].texture==Effects.EARTH_ART and strips[0].offset.y<0 and is_equal_approx(strips[0].position.y,game.CENTER.y+50),"actual shaped rock FX uses anchored dedicated artwork")
 for i in range(90):model.advance(1.0/60.0);await process_frame
 check(survivor.hp<5000 and off_row.hp==5000 and model.active.is_empty(),"freed initial target retains original ground point and rejects distant survivor")
 check(model.trace.any(func(event):return event.kind=="hit" and int(event.target)==survivor.get_instance_id()),"ground hit records the real survivor rather than target zero")
 model.reset_runtime();model.trace.clear();model.start(survivor);survivor.free()
 for i in range(120):model.advance(1.0/60.0);await process_frame
 check(model.active.is_empty() and model.trace.back().kind=="miss" and off_row.hp==5000,"freed target with no nearby victims finishes as an actual miss")
 clear()
 var bag: Node=preload("res://experiments/chain_lab/chain.gd").new();root.add_child(bag);bag.load_spell_kit();var before_items: Array=bag.items.duplicate(true);game.inventory.open(bag,2,1.0)
 check(bag.items.size()==21 and game.inventory.entries.get_children().filter(func(n):return n.visible).size()==15,"first inventory page shows fifteen cards without discarding owned items")
 game.inventory.cards.InventoryNext.pressed.emit()
 check(game.inventory.page==1 and game.inventory.entries.get_children().filter(func(n):return n.visible).size()==7 and game.inventory.cards["Item 20"].visible,"next-page control exposes final owned item")
 check(game.inventory.cards.InventoryNext.disabled and not game.inventory.cards.InventoryPrev.disabled,"last page has bounded navigation")
 game.inventory.cards.InventoryPrev.pressed.emit()
 check(game.inventory.page==0 and bag.items==before_items,"page navigation preserves all physical items")
 bag.queue_free();game.queue_free();await process_frame
 print("EARTH_RESULT "+JSON.stringify({"checks":checks,"failures":failures}));quit(0 if failures.is_empty() else 1)
