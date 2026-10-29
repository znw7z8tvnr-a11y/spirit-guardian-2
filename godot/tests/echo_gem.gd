extends SceneTree
const Rules=preload("res://experiments/chain_lab/gem_rules.gd")
const Catalog=preload("res://modules/spell/catalog.gd")
var checks: Array=[]
var failures: Array=[]
var emitted: Array=[]
func check(ok: bool,message: String) -> void:
 if ok:checks.append(message)
 else:failures.append(message)
func _initialize() -> void:call_deferred("run")
func record(slot: int,item: Dictionary,target: Node2D,cycle: Dictionary,context: Dictionary) -> void:emitted.append({"slot":slot,"item":item,"target":target,"run":cycle,"context":context})
func finish(model: Node,event: Dictionary,hit:=true) -> void:model.complete_skill(event.slot,event.target,{"hit":hit,"position":event.context.aim},event.run,event.context)
func run() -> void:
 var rng:=RandomNumberGenerator.new();rng.seed=101
 for level in range(1,4):
  check(is_equal_approx(Rules.echo_chance("echo",level),[0.2,0.35,0.5][level-1]),"source repeat probability at level %d" % level)
  var count:=0
  for i in range(10000):
   if rng.randf()<Rules.echo_chance("echo",level):count+=1
  check(absf(count/10000.0-Rules.echo_chance("echo",level))<0.025,"repeat probability distribution level %d" % level)
 var game: Node=load("res://experiments/chain_lab/main.tscn").instantiate();game.persist_book=false;root.add_child(game);current_scene=game;game.set_process(false);game.set_physics_process(false)
 var model: Node=game.chain
 model.items=[{"id":0,"kind":"skill","key":"arcane","level":1},{"id":1,"kind":"gem","key":"echo","level":3},{"id":2,"kind":"skill","key":"fire","level":1},{"id":3,"kind":"gem","key":"relay","level":3},{"id":4,"kind":"skill","key":"ice","level":1},{"id":5,"kind":"skill","key":"lightning","level":1}]
 model.slots=[0,1,2,3,4,5,-1,-1,-1,-1];model.edges=[{"from":0,"to":1},{"from":1,"to":2},{"from":1,"to":5},{"from":2,"to":3},{"from":3,"to":4}];model.resonance_chance=0
 var enemy:=preload("res://modules/enemy/enemy.gd").new();enemy.max_hp=5000;enemy.hp=5000;enemy.speed=0;enemy.target=Vector2(9999,9999);enemy.position=game.CENTER+Vector2(100,0);game.enemies.add_child(enemy);enemy.set_physics_process(false)
 model.cast_requested.disconnect(game.cast_spell);model.cast_requested.connect(record)
 model.start(enemy);finish(model,emitted.pop_front());model.advance(0.33);model.advance(0.33)
 check(emitted.size()==2 and emitted.all(func(e):return is_equal_approx(float(e.context.echo_chance),0.5)),"each fork child receives its own source repeat chance")
 # Force a successful roll only in this unit fixture to verify all duplicate paths.
 var a: Dictionary=emitted.pop_front();var b: Dictionary=emitted.pop_front();a.context.echo_chance=1.0;b.context.echo_chance=1.0
 finish(model,a);var pending_count: int=model.pending.size();finish(model,a)
 check(model.pending.size()==pending_count,"duplicate primary callback cannot queue another echo")
 finish(model,b);model.advance(0.33);model.advance(0.33)
 var echoes: Array=emitted.filter(func(e):return e.context.get("is_echo",false));var normal: Array=emitted.filter(func(e):return not e.context.get("is_echo",false))
 check(echoes.size()==2 and normal.size()==1 and normal[0].slot==4,"fork echoes do not duplicate subsequent graph traversal")
 check(normal[0].context.echo_chance==0,"repeat chance expires after the next skill")
 for e in emitted:
  if e.context.get("is_echo",false):e.context.echo_chance=1.0
  finish(model,e);finish(model,e)
 emitted.clear();model.advance(1.0)
 check(model.active.is_empty() and emitted.is_empty() and model.casts==6,"echo callbacks cannot recurse or leave inflight work")
 model.reset_runtime();model.edges=[];model.start(enemy);var stale: Dictionary=emitted.pop_front();stale.context.echo_chance=1.0;finish(model,stale);enemy.free();model.advance(0.33)
 check(emitted.size()==1 and emitted[0].target==null and emitted[0].context.is_echo,"freed last enemy still produces an empty echo")
 finish(model,emitted.pop_front(),false);check(model.active.is_empty() and model.trace.back().kind=="miss","empty echo settles without phantom hit")
 model.start(null);check(model.active.is_empty(),"echo does not start fresh rounds without targets")
 # Real projectiles with unchanged gameplay probability; choose a reproducible seed.
 enemy=preload("res://modules/enemy/enemy.gd").new();enemy.max_hp=5000;enemy.hp=5000;enemy.speed=0;enemy.target=Vector2(9999,9999);enemy.position=game.CENTER+Vector2(100,0);game.enemies.add_child(enemy);enemy.set_physics_process(false)
 model.edges=[{"from":0,"to":1},{"from":1,"to":2},{"from":2,"to":3},{"from":3,"to":4}]
 for seed_value in range(1,100):
  rng.seed=seed_value;rng.randf()
  if rng.randf()<0.5:model.rng.seed=seed_value;break
 model.cast_requested.disconnect(record);model.cast_requested.connect(game.cast_spell);model.start(enemy)
 for i in range(300):model.advance(1.0/60.0);await process_frame
 var expected: float=(Catalog.power("arcane")+Catalog.power("fire")*2+Catalog.power("ice"))*game.spell_attack_multiplier()
 check(is_equal_approx(5000-enemy.hp,expected),"real echo projectile adds exactly one fire impact of damage")
 check(game.spell_cast_counts.fire==2 and game.spell_cast_counts.ice==1 and model.active.is_empty(),"real damage repeat never duplicates downstream ice")
 model.reset_runtime();model.cast_requested.disconnect(game.cast_spell);model.cast_requested.connect(record);model.start(enemy);var capped: Dictionary=emitted.pop_front();capped.context.echo_chance=1.0;model.active.events=model.MAX_EVENTS;finish(model,capped)
 check(model.pending.is_empty() and model.active.is_empty(),"event budget bounds both continuations and echoes")
 game.queue_free();await process_frame
 print("ECHO_RESULT "+JSON.stringify({"checks":checks,"failures":failures}));quit(0 if failures.is_empty() else 1)
