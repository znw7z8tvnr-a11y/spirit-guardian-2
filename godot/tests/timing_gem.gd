extends SceneTree
const Rules=preload("res://experiments/chain_lab/gem_rules.gd")
const Chain=preload("res://experiments/chain_lab/chain.gd")
var checks: Array=[]
var failures: Array=[]
func check(ok: bool,message: String) -> void:
 if ok:checks.append(message)
 else:failures.append(message)
func _initialize() -> void:call_deferred("run")
func run() -> void:
 for level in range(1,4):
  var model:=Chain.new();var item: Dictionary={"id":1,"kind":"gem","key":"delay","level":level};var period: float=[3.0,2.0,1.0][level-1]
  check(Rules.delay_seconds(level)==period,"level %d source cooldown" % level)
  check(model.gem_succeeds(item,{"hit":false}) and model.gem_remaining(item)==period,"level %d first empty cast can activate immediately" % level)
  model.clock=period-0.01
  check(not model.gem_succeeds(item,{"hit":true}) and is_equal_approx(model.gem_remaining(item),0.01),"level %d blocks before exact deadline without extending it" % level)
  model.clock=period
  check(model.gem_succeeds(item,{"hit":false}),"level %d accepts exact deadline" % level)
  model.reset_runtime();check(model.gem_remaining(item)==period,"level %d graph reset preserves item cooldown" % level)
  var other: Dictionary=item.duplicate();other.id=2
  check(model.gem_succeeds(other,{}) and not model.gem_succeeds(item,{}),"level %d physical duplicates have independent cooldowns" % level)
  model.free()
 var model:=Chain.new();var timer: Dictionary={"id":1,"kind":"gem","key":"delay","level":1};model.items.append(timer);model.slots[1]=1;model.gem_succeeds(timer,{})
 check(model.equip(1,-1) and model.equip(3,1) and model.gem_remaining(timer)==3,"moving the same physical gem preserves its deadline")
 timer.level=3;model.clock=1
 check(model.gem_remaining(timer)==2,"changing level does not shorten an already running cooldown")
 model.clock=3;model.gem_succeeds(timer,{})
 check(model.gem_remaining(timer)==1,"new activation uses the new level period")
 model.free();model=Chain.new();check(model.gem_ready_at.is_empty(),"a new run starts without previous item cooldowns");model.free()
 var game: Node=load("res://experiments/chain_lab/main.tscn").instantiate();game.persist_book=false;root.add_child(game);current_scene=game;game.set_process(false);game.set_physics_process(false)
 game.remaining=0;game.attack_clock=100000
 model=game.chain;model.items=[{"id":0,"kind":"skill","key":"arcane","level":1},{"id":1,"kind":"gem","key":"delay","level":1},{"id":2,"kind":"skill","key":"fire","level":1}];model.slots=[0,1,2,-1,-1,-1,-1,-1,-1,-1];model.edges=[{"from":0,"to":1},{"from":1,"to":2}];model.resonance_chance=0
 var e:=preload("res://modules/enemy/enemy.gd").new();e.max_hp=5000;e.hp=5000;e.speed=0;e.target=Vector2(9999,9999);e.position=game.CENTER+Vector2(100,0);game.enemies.add_child(e);e.set_physics_process(false)
 model.start(e)
 for i in range(120):model.advance(1.0/60.0);await process_frame
 check(int(game.spell_cast_counts.get("fire",0))==1 and model.active.is_empty(),"real first activation emits one following projectile")
 model.start(e)
 for i in range(60):model.advance(1.0/60.0);await process_frame
 var gates: Array=model.trace.filter(func(event):return event.kind=="gem")
 check(gates.size()==2 and gates[1].reason=="cooldown" and int(game.spell_cast_counts.fire)==1,"real next round is blocked by cooldown without queuing another fire spell")
 check(game.trail.any(func(entry):return "冷卻中" in entry),"combat HUD shows actual remaining cooldown")
 var before: float=model.clock;var remaining: float=model.gem_remaining(model.items[1]);Engine.time_scale=8
 game.user_paused=true;game._physics_process(8)
 check(model.clock==before and model.gem_remaining(model.items[1])==remaining,"pause freezes gem cooldown at eight times speed")
 game.user_paused=false;game.edit_open=true;game._physics_process(8)
 check(model.clock==before,"configuration menu freezes gem clock")
 game.edit_open=false;game.growth_open=true;game._physics_process(8)
 check(model.clock==before,"growth menu freezes gem clock")
 game.growth_open=false;game.rewards.pending=1;game._physics_process(8)
 check(model.clock==before,"reward modal freezes gem clock")
 game.rewards.pending=0;Engine.time_scale=1;game._physics_process(remaining)
 check(is_zero_approx(model.gem_remaining(model.items[1])),"unpaused simulation delta expires cooldown at its deadline")
 model.start(e)
 for i in range(120):model.advance(1.0/60.0);await process_frame
 check(int(game.spell_cast_counts.fire)==2 and model.active.is_empty(),"expired cooldown produces exactly one real continuation again")
 model.reset_runtime();model.trace.clear();model.gem_ready_at.clear();model.items[1].level=3;model.items.append({"id":3,"kind":"skill","key":"ice","level":1});model.slots[3]=3;model.edges=[{"from":0,"to":1},{"from":1,"to":2},{"from":1,"to":3}]
 model.start(e)
 for i in range(120):model.advance(1.0/60.0);await process_frame
 var fork_gates: Array=model.trace.filter(func(event):return event.kind=="gem")
 check(fork_gates.size()==1 and game.spell_cast_counts.fire==3 and game.spell_cast_counts.ice==1,"level-three fork consumes one cooldown and emits both real branches")
 model.start(e);e.free()
 for i in range(120):model.advance(1.0/60.0);await process_frame
 check(model.active.is_empty() and model.empty_casts>=2 and game.spell_cast_counts.fire==4 and game.spell_cast_counts.ice==2,"freed enemy still allows a ready timer to settle both empty branches")
 game.queue_free();await process_frame
 print("TIMING_RESULT "+JSON.stringify({"checks":checks,"failures":failures}));quit(0 if failures.is_empty() else 1)
