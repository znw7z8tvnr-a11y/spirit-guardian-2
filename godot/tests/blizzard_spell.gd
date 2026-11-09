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
 check(Catalog.PLAYABLE.size()==8 and "blizzard" not in Catalog.PLAYABLE and Effects.PLAYABLE.size()==18 and Effects.PLAYABLE.slice(0,8)==Catalog.PLAYABLE,"blizzard is lab-only and stable root still advertises eight")
 check(Catalog.power("blizzard")==27 and Catalog.element("blizzard")=="ice","blizzard retains source damage and ice mapping")
 check(Effects.texture("blizzard").get_height()==192 and "暴風雪" in Effects.description("blizzard"),"blizzard has dedicated provisional faceted frost sprite and explicit radius description")
 for level in range(1,4):
  var e:=enemy(Vector2(100,100),root);var result:=Effects.impact("blizzard",e,Vector2.ZERO,e.position,level,1.5,[e],resolver)
  check(result.hit_count==1 and is_equal_approx(5000-e.hp,27*(1+0.55*(level-1))*1.5),"level %d applies real level and meat scaling" % level)
  var hp_after_cast: float=e.hp;e._physics_process(2.0)
  check(e.slow_time==0 and e.hp==hp_after_cast,"level %d slow expires without extra damage" % level);clear()
 var primary:=enemy(Vector2(100,100),root);enemy(Vector2(-54,100),root);enemy(Vector2(254,100),root);enemy(Vector2(100,254.9),root);var boundary:=enemy(Vector2(100,255),root)
 var row:=Effects.impact("blizzard",primary,Vector2.ZERO,primary.position,1,1,allocated,resolver)
 check(row.hit_count==4 and boundary.hp==5000,"ground radius includes inner victims and excludes exact one-hundred-fifty-five boundary")
 check(primary.slow_time==1.8 and primary.poison_time==0 and primary.position==Vector2(100,100),"blizzard applies existing ice slow without poison or displacement")
 check(row.hit_positions.size()==4 and not row.hit_positions.has(boundary.position),"visual hit positions include only actual damaged victims")
 var rules=preload("res://experiments/chain_lab/gem_rules.gd")
 check(not rules.eligible("burn",row,3) and rules.eligible("freeze",row,3) and row.slowed_hit,"actual ice slow permits freeze gem and rejects fire gem")
 primary._physics_process(0.6);Effects.impact("blizzard",primary,Vector2.ZERO,primary.position,1,1,[primary],resolver)
 check(is_equal_approx(primary.slow_time,1.8),"repeat ice hit refreshes duration without stacking slow time")
 check(row.target_id==primary.get_instance_id() and row.element=="ice","aggregate result identifies actual primary hit and element");clear()
 for i in range(25):enemy(Vector2(i,0),root)
 primary=enemy(Vector2(0,0),root);row=Effects.impact("blizzard",primary,Vector2.ZERO,primary.position,1,1,allocated,resolver)
 check(row.hit_count==24 and primary.hp==4973,"radius cap is twenty-four and selected target is retained")
 check(allocated.filter(func(e):return e.slow_time>0).size()==24,"only the twenty-four damaged victims receive slow")
 check(allocated.filter(func(e):return e.hp==4973).size()==24,"twenty-four real unique victims receive damage");clear()
 check(not Effects.impact("blizzard",null,Vector2.ZERO,Vector2.ZERO,1,1,[],resolver).hit,"empty ground produces no phantom hit")
 var game: Node=load("res://experiments/chain_lab/main.tscn").instantiate();game.persist_book=false;root.add_child(game);current_scene=game;game.set_process(false);game.set_physics_process(false)
 var visual_hits: Array=row.hit_positions.duplicate()
 game.spell_visual("blizzard",Vector2.ZERO,Vector2.ZERO,visual_hits)
 var visual: Node2D=game.fx.get_child(game.fx.get_child_count()-1)
 check(visual.get_child_count()==9,"twenty-four actual hit locations create one frost layer and at most eight falling shards")
 for i in range(18):await process_frame
 check(visual.get_children().slice(1).all(func(n):return visual_hits.any(func(point):return point.is_equal_approx(n.global_position))),"all bounded shard destinations come from supplied real hit locations")
 visual.free()
 game.spell_visual("blizzard",Vector2.ZERO,game.CENTER,[])
 visual=game.fx.get_child(game.fx.get_child_count()-1)
 check(visual.get_child_count()==2 and (visual.get_child(1).global_position+Vector2(0,80))==game.CENTER,"empty ground still shows one frost layer and one no-damage shard at original aim")
 visual.free()
 var model: Node=game.chain;model.items=[{"id":0,"kind":"skill","key":"arcane","level":1},{"id":1,"kind":"gem","key":"relay","level":3},{"id":2,"kind":"skill","key":"blizzard","level":2},{"id":3,"kind":"gem","key":"relay","level":3},{"id":4,"kind":"skill","key":"fire","level":1}];model.slots=[0,1,2,3,4,-1,-1,-1,-1,-1];model.edges=[{"from":0,"to":1},{"from":1,"to":2},{"from":2,"to":3},{"from":3,"to":4}];model.resonance_chance=0
 var first:=enemy(game.CENTER+Vector2(100,50),game.enemies);enemy(game.CENTER+Vector2(140,50),game.enemies);enemy(game.CENTER+Vector2(160,50),game.enemies);model.start(first);var first_run: Dictionary=model.active
 for i in range(240):model.advance(1.0/60.0);await process_frame
 check(game.spell_cast_counts.get("blizzard",0)==1 and game.spell_hit_counts.get("blizzard",0)==3,"real chain cast damages three ground targets")
 check("ice" in first_run.elements,"real chain records ice element without inventing a resonance recipe")
 check(game.spell_cast_counts.get("fire",0)==1 and model.active.is_empty(),"multi-victim blizzard advances its following gem exactly once");clear()
 model.reset_runtime();model.trace.clear();model.edges=[];model.slots.fill(-1);model.slots[0]=2
 first=enemy(game.CENTER+Vector2(140,50),game.enemies);var survivor:=enemy(game.CENTER+Vector2(180,50),game.enemies);var off_row:=enemy(game.CENTER+Vector2(500,300),game.enemies)
 model.start(first);first.free()
 for i in range(60):model.advance(1.0/60.0);await process_frame
 var strips: Array=game.fx.get_children().filter(func(node):return node.get_meta("spell_key","")=="blizzard")
 check(not strips.is_empty() and strips[0].get_child_count()==2 and strips[0].get_child(0).texture==Effects.BLIZZARD_ART and strips[0].get_child(1).texture==Effects.BLIZZARD_SHARD and is_equal_approx(strips[0].position.y,game.CENTER.y+50),"actual shaped hit-located frost-and-shard FX uses dedicated artwork")
 check(not strips.is_empty() and strips[0].get_child(1).global_position.is_equal_approx(survivor.position),"fallen ice shard is bound to actual survivor hit location")
 var hp_after_hit: float=survivor.hp
 for i in range(90):model.advance(1.0/60.0);await process_frame
 check(survivor.hp==hp_after_hit,"ice shower and fade do not deal recurring damage")
 check(survivor.hp<5000 and off_row.hp==5000 and model.active.is_empty(),"freed initial target retains original ground point and rejects distant survivor")
 check(model.trace.any(func(event):return event.kind=="hit" and int(event.target)==survivor.get_instance_id()),"ground hit records the real survivor rather than target zero")
 model.reset_runtime();model.trace.clear();model.start(survivor);survivor.free()
 for i in range(120):model.advance(1.0/60.0);await process_frame
 check(model.active.is_empty() and model.trace.back().kind=="miss" and off_row.hp==5000,"freed target with no nearby victims finishes as an actual miss")
 clear()
 game.queue_free();await process_frame
 print("BLIZZARD_RESULT "+JSON.stringify({"checks":checks,"failures":failures}));quit(0 if failures.is_empty() else 1)
