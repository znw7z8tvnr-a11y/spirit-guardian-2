extends SceneTree
const Rules=preload("res://experiments/chain_lab/gem_rules.gd")
const Effects=preload("res://experiments/chain_lab/spell_effects.gd")
var checks: Array=[]
var failures: Array=[]
func check(ok: bool,message: String) -> void:
 if ok:checks.append(message)
 else:failures.append(message)
func _initialize() -> void:call_deferred("run")
func battle_case(game: Node,spell: String,gem: String,slowed: float,health: float,empty: bool,expected: bool) -> void:
 var model: Node=game.chain;model.reset_runtime();model.trace.clear();game.spell_cast_counts.clear()
 for old in game.enemies.get_children():old.free()
 model.items=[{"id":0,"kind":"skill","key":spell,"level":1},{"id":1,"kind":"gem","key":gem,"level":3},{"id":2,"kind":"skill","key":"arcane","level":1}]
 model.slots=[0,1,2,-1,-1,-1,-1,-1,-1,-1];model.edges=[{"from":0,"to":1},{"from":1,"to":2}];model.resonance_chance=0
 var predictor:=RandomNumberGenerator.new()
 for seed_value in range(1,100):
  predictor.seed=seed_value
  if predictor.randf()<0.9:model.rng.seed=seed_value;break
 var e:=preload("res://modules/enemy/enemy.gd").new();e.max_hp=health;e.hp=health;e.speed=0;e.target=Vector2(9999,9999);e.position=game.CENTER+Vector2(100,0);e.slow_time=slowed;game.enemies.add_child(e);e.set_physics_process(false)
 model.start(e)
 if empty:e.free()
 for i in range(180):model.advance(1.0/60.0);await process_frame
 var casts: Array=model.trace.filter(func(event):return event.kind=="cast" and int(event.slot)==2)
 var gates: Array=model.trace.filter(func(event):return event.kind=="gem")
 var label: String="%s -> %s slow=%s hp=%s empty=%s" % [spell,gem,slowed,health,empty]
 check((casts.size()==1)==expected,label+" actual conditional continuation")
 check(gates.size()==1 and bool(gates[0].eligible)==expected,label+" one snapshot-backed condition result")
 check(model.active.is_empty(),label+" round settles")
func run() -> void:
 for key in ["burn","freeze"]:
  for level in range(1,4):check(is_equal_approx(Rules.RATES[key][level-1],[0.4,0.65,0.9][level-1]),"%s level %d source rate" % [key,level])
  check(not Rules.eligible(key,{"hit":false,"element":"ice" if key=="freeze" else "fire","slowed_hit":true}),key+" rejects misses even with stale elemental flags")
 check(not Rules.eligible("burn",{"hit":true,"element":"ice","slowed_hit":true}),"slowed target cannot satisfy fire condition")
 check(Rules.eligible("freeze",{"hit":true,"element":"arcane","slowed_hit":true}),"non-ice hit accepts actual slowed victim snapshot")
 var game: Node=load("res://experiments/chain_lab/main.tscn").instantiate();game.persist_book=false;root.add_child(game);current_scene=game;game.set_process(false);game.set_physics_process(false)
 for spec in [["fire","burn",0.0,5000.0,false,true],["meteor","burn",0.0,5000.0,false,true],["ice","freeze",0.0,5000.0,false,true],["nova","freeze",0.0,5000.0,false,true],["arcane","freeze",1.0,5000.0,false,true],["arcane","burn",0.0,5000.0,false,false],["fire","freeze",0.0,5000.0,false,false],["fire","burn",0.0,5000.0,true,false],["fire","burn",0.0,1.0,false,true],["ice","freeze",0.0,1.0,false,true]]:
  await battle_case(game,spec[0],spec[1],spec[2],spec[3],spec[4],spec[5])
 var model: Node=game.chain;model.reset_runtime()
 model.items=[{"id":0,"kind":"skill","key":"arcane","level":1},{"id":1,"kind":"gem","key":"burn","level":3},{"id":2,"kind":"gem","key":"relay","level":3},{"id":3,"kind":"skill","key":"fire","level":1},{"id":4,"kind":"gem","key":"freeze","level":3},{"id":5,"kind":"skill","key":"ice","level":1}]
 for seed_value in range(10):
  model.rng.seed=seed_value;model.random_arrange()
  var compatible:=true
  for edge in model.edges:
   if model.item_at(int(edge.to)).kind=="gem":compatible=compatible and Rules.may_follow(str(model.item_at(int(edge.to)).key),preload("res://modules/spell/catalog.gd").element(str(model.item_at(int(edge.from)).key)))
  check(compatible and model.reachable_skill_count()>=2,"random arrange seed %d keeps a usable starter and compatible elemental gates" % seed_value)
 model.items.append({"id":6,"kind":"skill","key":"poison","level":1});model.items.append({"id":7,"kind":"gem","key":"relay","level":3});model.discovered=["fire+ice+poison"]
 check(model.arrange_discovered() and model.item_at(1).key=="relay" and model.item_at(3).key=="burn" and model.item_at(5).key=="freeze","known recipe pairs owned gems with preceding element")
 model.items=[{"id":0,"kind":"skill","key":"arcane","level":1},{"id":1,"kind":"gem","key":"burn","level":3},{"id":2,"kind":"gem","key":"freeze","level":3},{"id":3,"kind":"skill","key":"fire","level":1},{"id":4,"kind":"skill","key":"ice","level":1},{"id":5,"kind":"skill","key":"poison","level":1},{"id":6,"kind":"gem","key":"burn","level":3}]
 model.slots=[0,-1,-1,-1,-1,-1,-1,-1,-1,-1];model.edges=[];var before: Array=model.slots.duplicate()
 check(not model.arrange_discovered() and model.slots==before and model.edges.is_empty(),"known recipe preserves current setup when no gem can follow starter arcane")
 game.queue_free();await process_frame
 print("ELEMENTGEMS_RESULT "+JSON.stringify({"checks":checks,"failures":failures}));quit(0 if failures.is_empty() else 1)
