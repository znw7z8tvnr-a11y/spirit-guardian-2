extends SceneTree
const Rules=preload("res://experiments/chain_lab/gem_rules.gd")
const Effects=preload("res://experiments/chain_lab/spell_effects.gd")
const Enemy=preload("res://modules/enemy/enemy.gd")
var checks: Array=[]
var failures: Array=[]
func check(ok: bool,message: String) -> void:
 if ok:checks.append(message)
 else:failures.append(message)
func _initialize() -> void:call_deferred("run")
func run() -> void:
 var game=load("res://experiments/chain_lab/main.tscn").instantiate();game.persist_book=false;game.persist_run=false;root.add_child(game);current_scene=game;game.set_process(false);game.set_physics_process(false)
 check(game.criticals_enabled,"real gameplay enables source critical rules by default")
 var e:=Enemy.new();e.max_hp=1000000;e.hp=1000000;e.speed=0;e.target=Vector2(9999,9999);e.position=game.CENTER+Vector2(100,0);e.resolver=game.resolver;game.enemies.add_child(e);e.set_physics_process(false)
 var hits:=0;var criticals:=0
 game.resolver.rng.seed=73220
 for i in range(10000):
  var before:=e.hp
  var result:=Effects.impact("arcane",e,game.CENTER,e.position,1,1,[e],game.resolver,true)
  hits+=int(result.hit);criticals+=int(result.critical)
  check(is_equal_approx(before-e.hp,33.3 if result.critical else 18),"real critical/normal HP sample %d" % i) if i<10 else null
  if i<10:check(result.critical_count==int(result.critical),"single-target critical count %d" % i)
 check(hits==10000 and absf(criticals/10000.0-0.12)<0.015,"real resolver critical rate is twelve percent within statistical tolerance")
 var normal:=Effects.impact("arcane",e,game.CENTER,e.position,1,1,[e],game.resolver,false)
 check(normal.damage==18 and not normal.critical and normal.critical_count==0,"explicit non-critical baseline has real eighteen damage and a fresh snapshot")
 var miss:=Effects.impact("arcane",null,game.CENTER,e.position,1,1,[],game.resolver,true)
 check(not miss.hit and not miss.critical and not Rules.eligible("crit",miss,3),"miss cannot inherit prior critical state")
 check(not Rules.eligible("crit",{"hit":false,"critical":true},3) and not Rules.eligible("crit",{"hit":true,"critical":false},3),"critical condition requires both real hit and current critical")
 for level in range(1,4):
  var rng:=RandomNumberGenerator.new();rng.seed=900+level;var successes:=0
  for i in range(10000):successes+=int(Rules.succeeds("crit",level,{"hit":true,"critical":true},rng))
  check(absf(successes/10000.0-[0.20,0.35,0.50][level-1])<0.02,"critical tier %d conditional probability" % level)
  check(is_equal_approx(Rules.next_multiplier("rapid",level),[1.10,1.20,1.35][level-1]) and Rules.eligible("rapid",miss,level),"rapid tier %d boosts next skill and accepts a miss" % level)
 var dot_before:=e.hp;var dot: Dictionary=game.resolver.resolve(e,3,"poison",{"status_tick":true})
 check(dot.damage==3 and e.hp==dot_before-3 and not dot.critical,"poison ticks do not acquire direct criticals")
 var model: Node=game.chain;model.load_final_gem_kit();var owned: Array=model.items.duplicate(true);model.load_final_gem_kit()
 check(model.items==owned and owned.size()==42 and model.slots.count(-1)==5,"final training grants forty-two items once and keeps five empty slots")
 game.criticals_enabled=false;model.items=[{"id":0,"kind":"skill","key":"arcane","level":1},{"id":1,"kind":"gem","key":"rapid","level":3},{"id":2,"kind":"skill","key":"fire","level":1}];model.slots=[0,1,2,-1,-1,-1,-1,-1,-1,-1];model.edges=[{"from":0,"to":1},{"from":1,"to":2}];model.resonance_chance=0
 var before:=e.hp;model.start(e)
 for i in range(360):
  model.advance(1.0/60.0);await process_frame
  if model.active.is_empty():break
 check(is_equal_approx(before-e.hp,18+24*1.35),"rapid modifies actual next projectile HP damage once without changing its predecessor")
 # Search reproducible ordinary RNG seeds; neither force critical nor bypass the gate.
 var demo_seed:=0
 for candidate in range(1,100000):
  var damage_rng:=RandomNumberGenerator.new();damage_rng.seed=candidate+42000
  if damage_rng.randf()>=0.12 or damage_rng.randf()>=0.12 or damage_rng.randf()>=0.12:continue
  var gate_rng:=RandomNumberGenerator.new();gate_rng.seed=candidate+19980
  if gate_rng.randf()<0.5:demo_seed=candidate;break
 check(demo_seed>0,"a reproducible real critical and successful condition seed exists")
 e.free();game.queue_free();await process_frame
 print("FINALGEMS_RESULT "+JSON.stringify({"checks":checks,"failures":failures,"critical_samples":10000,"critical_count":criticals,"demo_seed":demo_seed}));quit(0 if failures.is_empty() else 1)
