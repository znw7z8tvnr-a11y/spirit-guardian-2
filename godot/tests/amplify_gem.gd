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
func finish(model: Node,event: Dictionary) -> void:model.complete_skill(event.slot,event.target,{"hit":true,"position":event.context.aim},event.run,event.context)
func run() -> void:
 for level in range(1,4):
  check(is_equal_approx(Rules.next_multiplier("split",level),[1.1,1.2,1.35][level-1]),"source level %d bonus" % level)
 var game: Node=load("res://experiments/chain_lab/main.tscn").instantiate();game.persist_book=false;root.add_child(game);current_scene=game
 game.set_process(false);game.set_physics_process(false)
 var model: Node=game.chain
 model.items=[{"id":0,"kind":"skill","key":"arcane","level":1},{"id":1,"kind":"gem","key":"split","level":3},{"id":2,"kind":"skill","key":"fire","level":1},{"id":3,"kind":"gem","key":"relay","level":3},{"id":4,"kind":"skill","key":"arcane","level":1},{"id":5,"kind":"skill","key":"ice","level":1}]
 model.slots=[0,1,2,3,4,5,-1,-1,-1,-1]
 model.edges=[{"from":0,"to":1},{"from":1,"to":2},{"from":1,"to":5},{"from":2,"to":3},{"from":3,"to":4}];model.resonance_chance=0
 var enemy:=preload("res://modules/enemy/enemy.gd").new();enemy.max_hp=5000;enemy.hp=5000;enemy.speed=0;enemy.target=Vector2(9999,9999);enemy.position=game.CENTER+Vector2(100,0);game.enemies.add_child(enemy);enemy.set_physics_process(false)
 model.cast_requested.disconnect(game.cast_spell);model.cast_requested.connect(record)
 model.start(enemy);var first: Dictionary=emitted.pop_front();finish(model,first)
 check(float(first.context.get("damage_scale",1.0))==1.0,"preceding attack is not amplified")
 model.advance(0.33);model.advance(0.33)
 check(emitted.size()==2 and emitted.all(func(e):return is_equal_approx(float(e.context.damage_scale),1.35)),"both branches inherit next-skill bonus independently")
 var left: Dictionary=emitted.pop_front();var right: Dictionary=emitted.pop_front();finish(model,left);model.advance(0.33);model.advance(0.33)
 check(emitted.size()==1 and float(emitted[0].context.damage_scale)==1.0,"bonus expires after one skill and relay does not carry it forever")
 check(is_equal_approx(float(right.context.damage_scale),1.35),"completing one branch never consumes sibling bonus")
 finish(model,emitted.pop_front());finish(model,right)
 check(model.active.is_empty(),"amplified fork settles without inflight leak")
 model.reset_runtime();model.cast_requested.disconnect(record);model.cast_requested.connect(game.cast_spell)
 var initial: float=enemy.hp
 model.start(enemy)
 for i in range(300):
  model.advance(1.0/60.0);await process_frame
 var expected: float=(Catalog.power("arcane")*2+(Catalog.power("fire")+Catalog.power("ice"))*1.35)*game.spell_attack_multiplier()
 check(is_equal_approx(initial-enemy.hp,expected),"actual projectile impacts apply bonus to fire and ice only")
 check(model.active.is_empty() and model.hits==8,"real flight completes all four attacks without extra hit callbacks")
 game.queue_free();await process_frame
 print("AMPLIFY_RESULT "+JSON.stringify({"checks":checks,"failures":failures}));quit(0 if failures.is_empty() else 1)
