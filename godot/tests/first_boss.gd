extends SceneTree
var checks: Array=[]
var failures: Array=[]
var battles: Array=[]
func check(ok: bool,message: String) -> void:
 if ok:checks.append(message)
 else:failures.append(message)
func _initialize() -> void:call_deferred("run")
func run() -> void:
 var probe=load("res://experiments/chain_lab/main.tscn").instantiate();probe.persist_book=false;root.add_child(probe);current_scene=probe;probe.set_physics_process(false)
 probe.wave=5;probe.remaining=9
 var boss: Node2D=probe.spawn_enemy();boss.apply_hit(boss.max_hp*0.35,"arcane")
 check(boss.phase==2 and probe.summoned_minions==3 and probe.enemies.get_child_count()==4,"real phase-two signal creates three configured minions")
 var minion: Node2D=probe.enemies.get_child(1)
 check(minion.entity_id!=boss.entity_id and minion.target==probe.CENTER and minion.max_hp==43 and minion.resolver==probe.resolver,"summons share combat interfaces and wave-five scaling")
 var remaining: int=probe.remaining
 probe.spawn_boss_minions(boss,100)
 check(probe.enemies.get_child_count()==40 and probe.remaining==remaining,"summons respect the forty-enemy cap without consuming scheduled wave spawns")
 var amount: int=probe.summoned_minions;boss.dead=true;probe.spawn_boss_minions(boss,3)
 check(probe.summoned_minions==amount,"dead Boss cannot create late summons")
 boss.dead=false;boss.move="crystalSpear";boss.warning=0.8;boss.warning_total=1.5;probe.refresh_status()
 check(probe.boss_health.visible and probe.boss_info.phase==2 and probe.boss_label.text.contains("裂晶槍"),"Boss HUD shows health, stage and localized warning")
 minion.take_damage(1000);probe.on_enemy_died(minion);probe.collect_all_flesh()
 check(probe.tower.total_absorbed==4,"summoned ordinary enemy drops meat exactly once")
 probe.chain.items.append({"id":1,"kind":"gem","key":"relay","level":1});probe.chain.items.append({"id":2,"kind":"skill","key":"fire","level":1})
 probe.chain.equip(1,1);probe.chain.equip(2,2);probe.chain.connect_slots(0,1);probe.chain.connect_slots(1,2)
 check(probe.effective_attack_period()==1.8,"two-skill starter chain uses responsive cadence without altering long-chain presets")
 probe.queue_free();await process_frame
 for seed_value in [12032,24064,32012]:
  var game=load("res://experiments/chain_lab/main.tscn").instantiate();game.persist_book=false;root.add_child(game);current_scene=game
  game.rng.seed=seed_value;game.chain.rng.seed=seed_value+19980;game.rewards.rng.seed=seed_value+31000
  game.cycle_speed();game.cycle_speed();game.cycle_speed()
  var frames:=0;var min_wall_ratio:=1.0;var min_core:=100.0;var attacks:=0;var phase:=0;var pauses:=0;var warning_seen:=false;var short_period:=0.0
  while not game.over and game.wave<7 and frames<6000:
   if game.rewards.pending>0:
    var has_gem: bool=game.chain.items.any(func(item):return item.kind=="gem")
    var skills: int=game.chain.items.filter(func(item):return item.kind=="skill").size()
    var picked:=0
    for i in game.rewards.offers.size():
     var item: Dictionary=game.rewards.offers[i]
     if (not has_gem and item.kind=="gem") or (has_gem and skills<2 and item.kind=="skill") or (has_gem and skills>=2 and item.kind=="affix" and item.key=="power"):picked=i;break
    game.rewards.choose(picked)
   if game.edit_open:
    pauses+=1;var clock: float=game.combat_seconds;game._physics_process(0.5)
    check(game.combat_seconds==clock,"seed %d reward loadout waits for confirmation" % seed_value)
    game.chain.random_arrange()
    if game.chain.reachable_skill_count()==2:short_period=game.effective_attack_period()
    game.buttons.Done.pressed.emit()
   for enemy in game.enemies.get_children():
    if enemy.kind==5:attacks=maxi(attacks,enemy.attacks);phase=maxi(phase,enemy.phase);warning_seen=warning_seen or enemy.warning>0
   min_wall_ratio=minf(min_wall_ratio,game.tower.wall_hp/game.tower.wall_max);min_core=minf(min_core,game.tower.hp)
   await physics_frame;frames+=1
  check(game.wave>=7 and not game.over and game.boss_kills==1,"seed %d survives five waves, real Boss and following wave without kit" % seed_value)
  check(game.summoned_minions>=3 and phase==3 and attacks>0 and warning_seen,"seed %d observes real three-phase attacks and summons" % seed_value)
  check(not game.chain.kit_loaded and game.rewards.granted_count>=3 and pauses>=3,"seed %d progression uses only earned rewards and explicit loadout confirmation" % seed_value)
  check(game.chain.jumps>0,"seed %d builds a real earned chain that jumps between living enemies" % seed_value)
  var legal:=true;var ids: Array=[]
  for id in game.chain.slots:
   if id>=0:
    if id in ids:legal=false
    ids.append(id)
  for edge in game.chain.edges:
   if not game.chain.legal_edge(edge.from,edge.to,false):legal=false
  check(legal,"seed %d earned loadout preserves physical items and alternating graph" % seed_value)
  battles.append({"seed":seed_value,"wave":game.wave,"seconds":game.combat_seconds,"core":game.tower.hp,"min_core":min_core,"min_wall_ratio":min_wall_ratio,"boss_kills":game.boss_kills,"boss_attacks":attacks,"boss_phase":phase,"summons":game.summoned_minions,"kills":game.kills,"awards":game.rewards.granted_count,"jumps":game.chain.jumps,"loadout_pauses":pauses,"slots":game.chain.slots.duplicate(),"kit":game.chain.kit_loaded})
  game.queue_free();await process_frame
 print("FIRSTBOSS_RESULT "+JSON.stringify({"checks":checks,"failures":failures,"battles":battles}));quit(1 if failures.size() else 0)
