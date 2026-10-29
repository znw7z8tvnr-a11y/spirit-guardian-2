extends SceneTree
const Rules=preload("res://experiments/chain_lab/gem_rules.gd")
const Effects=preload("res://experiments/chain_lab/spell_effects.gd")
var checks: Array=[]
var failures: Array=[]
func check(ok: bool,message: String) -> void:
 if ok:checks.append(message)
 else:failures.append(message)
func _initialize() -> void:call_deferred("run")
func enemy(game: Node,maximum: float,health: float,at: Vector2) -> Node2D:
 var e:=preload("res://modules/enemy/enemy.gd").new();e.max_hp=maximum;e.hp=health;e.speed=0;e.target=Vector2(9999,9999);e.position=at;game.enemies.add_child(e);e.set_physics_process(false);return e
func battle(game: Node,level: int,health: float,empty: bool,expected: bool,key: String="lowhp") -> void:
 var model: Node=game.chain;model.reset_runtime();model.trace.clear();game.trail.clear()
 for old in game.enemies.get_children():old.free()
 model.items=[{"id":0,"kind":"skill","key":"arcane","level":1},{"id":1,"kind":"gem","key":key,"level":level},{"id":2,"kind":"skill","key":"fire","level":1}]
 model.slots=[0,1,2,-1,-1,-1,-1,-1,-1,-1];model.edges=[{"from":0,"to":1},{"from":1,"to":2}];model.resonance_chance=0
 if key=="relay":
  var predictor:=RandomNumberGenerator.new()
  for seed_value in range(1,100):
   predictor.seed=seed_value
   if predictor.randf()>=0.85:model.rng.seed=seed_value;break
 var e:=enemy(game,100,health,game.CENTER+Vector2(100,0));model.start(e)
 if empty:e.free()
 for i in range(180):model.advance(1.0/60.0);await process_frame
 var gates: Array=model.trace.filter(func(event):return event.kind=="gem")
 var casts: Array=model.trace.filter(func(event):return event.kind=="cast" and int(event.slot)==2)
 var label: String="%s level %d initial hp %s empty %s" % [key,level,health,empty]
 check((casts.size()==1)==expected and model.active.is_empty(),label+" actual projectile continuation and settlement")
 var reason: String="success" if expected else "chance" if key=="relay" else "condition"
 check(gates.size()==1 and gates[0].reason==reason,label+" distinguishes chance and condition failure")
 var verdict: String="接續成功" if expected else "機率未觸發" if key=="relay" else "條件未滿足"
 check(game.trail.any(func(entry):return verdict in entry),label+" visible combat verdict")
func run() -> void:
 for level in range(1,4):
  var cutoff: float=[0.25,0.40,0.55][level-1]
  check(Rules.eligible("lowhp",{"hit":true,"lowest_hp_ratio":cutoff},level),"level %d accepts exact threshold" % level)
  check(not Rules.eligible("lowhp",{"hit":true,"lowest_hp_ratio":cutoff+0.0001},level),"level %d rejects above threshold" % level)
 check(not Rules.eligible("lowhp",{"hit":false,"lowest_hp_ratio":0},3),"miss cannot fake low health or kill")
 for source in [{"hit":true},{"hit":true,"lowest_hp_ratio":INF},{"hit":true,"lowest_hp_ratio":-1}]:check(not Rules.eligible("lowhp",source,3),"invalid or missing ratio fails closed")
 var game: Node=load("res://experiments/chain_lab/main.tscn").instantiate();game.persist_book=false;root.add_child(game);current_scene=game;game.set_process(false);game.set_physics_process(false)
 for level in range(1,4):
  var health: float=[43.0,58.0,73.0][level-1]
  await battle(game,level,health,false,true);await battle(game,level,health+0.1,false,false)
 await battle(game,1,1,false,true)
 await battle(game,3,1,true,false)
 await battle(game,1,100,false,false,"relay")
 for old in game.enemies.get_children():old.free()
 var primary:=enemy(game,1000,1000,game.CENTER);var near:=enemy(game,100,20,game.CENTER+Vector2(100,0))
 var result:=Effects.impact("fire",primary,game.CENTER-Vector2(100,0),game.CENTER,1,1,[primary,near],game.resolver)
 check(result.hit_count==2 and Rules.eligible("lowhp",result,1),"actual splash victim can satisfy low-health snapshot")
 var far:=enemy(game,100,1,game.CENTER+Vector2(600,0))
 result=Effects.impact("arcane",primary,game.CENTER-Vector2(100,0),game.CENTER,1,1,[primary,far],game.resolver)
 check(result.hit_count==1 and not Rules.eligible("lowhp",result,3),"unhit low-health enemy cannot satisfy condition")
 var shielded:=enemy(game,100,100,game.CENTER);shielded.shield=50
 result=Effects.impact("arcane",shielded,game.CENTER-Vector2(100,0),game.CENTER,1,1,[shielded],game.resolver)
 check(result.hit and result.damage==0 and not Rules.eligible("lowhp",result,3),"absorbed hit uses actual remaining health")
 var model: Node=game.chain;model.reset_runtime();model.items=[{"id":0,"kind":"skill","key":"arcane","level":1},{"id":1,"kind":"gem","key":"lowhp","level":1},{"id":2,"kind":"gem","key":"relay","level":3},{"id":3,"kind":"skill","key":"fire","level":1}]
 for seed_value in range(10):model.rng.seed=seed_value;model.random_arrange();check(model.item_at(1).key=="relay","random seed %d prefers reliable starter over conditional lowhp" % seed_value)
 game.queue_free();await process_frame
 print("LOWHP_RESULT "+JSON.stringify({"checks":checks,"failures":failures}));quit(0 if failures.is_empty() else 1)
