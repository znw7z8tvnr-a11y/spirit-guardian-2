extends SceneTree
var checks: Array=[]
var failures: Array=[]
var runs: Array=[]
var cp_store=preload("res://experiments/chain_lab/checkpoint_store.gd").new()
func check(ok: bool,message: String) -> void:
 if ok:checks.append(message)
 else:failures.append(message)
func _initialize() -> void:call_deferred("run")
func choose_reward(game: Node,target_skills: int,refresh_build: bool) -> void:
 var gems: int=game.chain.items.filter(func(i):return i.kind=="gem").size()
 var skills: int=game.chain.items.filter(func(i):return i.kind=="skill").size()
 var picked:=0
 for i in game.rewards.offers.size():
  var item: Dictionary=game.rewards.offers[i]
  if (gems<skills and item.kind=="gem") or (gems>=skills and skills<target_skills and item.kind=="skill") or (gems>=skills and skills>=target_skills and item.kind=="affix" and item.key==("refresh" if refresh_build else "power")):picked=i;break
 game.rewards.choose(picked)
func run() -> void:
 var probe=load("res://experiments/chain_lab/main.tscn").instantiate();probe.persist_book=false;probe.persist_run=false;root.add_child(probe);current_scene=probe;probe.set_process(false);probe.set_physics_process(false)
 check(not probe.finish_run("victory") and not probe.finish_run("defeat") and probe.run_summary.is_empty(),"early victory and alive defeat requests fail closed")
 probe.wave=20;probe.boss_kills=4;probe.remaining=0
 check(not probe.finish_run("victory"),"jumping to wave twenty cannot invent nineteen completed waves")
 probe.tower.take_damage(1000000)
 check(probe.run_outcome=="defeat" and probe.result_view.visible and probe.run_summary.core==0,"real lethal wall/core damage opens defeat summary")
 var saved: Dictionary=probe.run_summary.duplicate(true);probe.tower.take_damage(1000000);probe.finish_run("defeat")
 check(probe.run_summary==saved,"duplicate destruction and finish calls cannot change the completed snapshot")
 probe.buttons.ResultRestart.pressed.emit();await process_frame;await process_frame
 var restarted: Node=current_scene;restarted.set_process(false);restarted.set_physics_process(false)
 check(not is_instance_valid(probe) and not restarted.over and restarted.run_summary.is_empty() and restarted.chain.items.size()==1 and restarted.chain.slots==[0,-1,-1,-1,-1,-1,-1,-1,-1,-1],"actual scene reload resets inventory and graph to arcane-only start")
 check(restarted.tower.hp==100 and restarted.tower.wall_hp==360 and restarted.tower.flesh==0 and restarted.tower.levels.values().all(func(v):return v==0) and restarted.rewards.completed.is_empty() and restarted.boss_kills==0 and Engine.time_scale==1,"restart resets flesh, growth, wall, rewards, Boss count and speed")
 restarted.queue_free();await process_frame
 for seed_value in [12032,24064,32012]:
  var game=load("res://experiments/chain_lab/main.tscn").instantiate();game.persist_book=false;game.persist_run=false;root.add_child(game);current_scene=game
  game.rng.seed=seed_value;game.chain.rng.seed=seed_value+19980;game.rewards.rng.seed=seed_value+31000;game.resolver.rng.seed=seed_value+42000
  game.cycle_speed();game.cycle_speed();game.cycle_speed()
  var verified: Dictionary={}
  var frames:=0;var seen_wave:=0;var checkpoints: Array=[];var min_wall:=1.0;var min_core:=100.0;var peak_enemies:=0
  while not game.over and frames<20000:
   var cp: Dictionary=cp_store.capture(game)
   if not cp.is_empty() and not verified.has(game.wave):
    verified[game.wave]=true
    check(cp_store.validate(cp),"seed %d wave %d live safe checkpoint validates" % [seed_value,game.wave])
   if game.rewards.pending>0:choose_reward(game,2 if seed_value==24064 else 5,seed_value==32012)
   if game.edit_open and game.rewards.pending==0:game.chain.random_arrange();game.buttons.Done.pressed.emit()
   min_wall=minf(min_wall,game.tower.wall_hp/game.tower.wall_max);min_core=minf(min_core,game.tower.hp);peak_enemies=maxi(peak_enemies,game.enemies.get_child_count())
   if game.wave!=seen_wave:
    seen_wave=game.wave;checkpoints.append({"wave":game.wave,"seconds":game.combat_seconds,"core":game.tower.hp,"wall":game.tower.wall_hp,"wall_max":game.tower.wall_max,"items":game.chain.items.size(),"growth":game.tower.levels.duplicate()})
   await physics_frame;frames+=1
  check(verified.size()==20,"seed %d has a safe checkpoint at all twenty waves" % seed_value)
  check(game.run_outcome=="victory" and game.wave==20 and game.boss_kills==4,"seed %d completes twenty real waves and four Bosses with earned rewards" % seed_value)
  check(game.rewards.pending==0 and range(1,21).all(func(w):return game.rewards.completed.has(w)),"seed %d claims final awards and has all twenty completed wave records" % seed_value)
  check(not game.chain.kit_loaded and not game.enemy_drill and not game.run_summary.training,"seed %d uses normal progression without training inventory or a drill shortcut" % seed_value)
  check(game.result_view.visible and game.result_view.heading.text=="二十波守護成功" and game.run_summary.kills==game.kills and game.run_summary.awards==game.rewards.granted_count and game.run_summary.cleared_waves==20,"seed %d result screen is derived from real combat counters" % seed_value)
  var clock: float=game.combat_seconds;var inventory_count: int=game.chain.items.size();var summary: Dictionary=game.run_summary.duplicate(true)
  game._physics_process(10);game.rewards.complete_wave(20,true)
  check(game.combat_seconds==clock and game.chain.items.size()==inventory_count and game.run_summary==summary and game.rewards.pending==0,"seed %d cannot continue simulation or double-grant final rewards after completion" % seed_value)
  check(peak_enemies<=40 and game.chain.slots.size()==10,"seed %d respects live enemy and physical slot caps for the full run" % seed_value)
  runs.append({"seed":seed_value,"target_skills":2 if seed_value==24064 else 5,"prefer_refresh":seed_value==32012,"summary":summary,"minimum_wall_ratio":min_wall,"minimum_core":min_core,"peak_enemies":peak_enemies,"frames":frames,"checkpoints":checkpoints})
  game.queue_free();await process_frame
 print("FULLRUN_RESULT "+JSON.stringify({"checks":checks,"failures":failures,"runs":runs,"limit":"Three deterministic native policies at eight-times speed; not all random builds, Safari hardware or final balance certification."}));quit(0 if failures.is_empty() else 1)
