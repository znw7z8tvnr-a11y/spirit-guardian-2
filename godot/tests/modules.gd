extends SceneTree
var failures: Array[String]=[]
var checks: Array[String]=[]
var game: Node2D
const Chain=preload("res://modules/chain_graph/chain_graph.gd")
const Growth=preload("res://modules/progression/progression.gd")
const Boss=preload("res://modules/boss/boss.gd")
const Catalog=preload("res://modules/spell/catalog.gd")
func _initialize() -> void:call_deferred("run")
func check(condition: bool, text: String) -> void:
 if condition:checks.append(text)
 else:failures.append(text)
func frames(count: int) -> void:
 for i in count:await physics_frame
func clear_arena() -> void:
 for e in game.enemies.get_children():e.queue_free()
 for p in game.projectiles.get_children():p.queue_free()
 game.remaining=0;game.attack_clock=999;game.intermission=999
 game.chain.reset_runtime()
 await frames(2)
func victim(kind: int=0) -> Node2D:
 var e: Node2D=game.spawn_enemy(kind)
 e.position=game.CENTER+Vector2(180,0);e.speed=0;e.hp=100000;e.max_hp=100000;e.damage=0
 return e
func run() -> void:
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);current_scene=game
 await frames(2)
 game.attack_clock=999;game.intermission=999
 check(Catalog.data.SK.size()==22 and Catalog.data.GEM.size()==19,"source data preserves all 22 spells and 19 gems")
 check(Catalog.PLAYABLE.size()==8,"runtime advertises eight supported spells, not all catalog entries")
 check(game.chain.nodes.size()>4,"default graph exceeds four nodes")
 var build: Dictionary=game.chain.build()
 check(not game.chain.connect_nodes(4,1),"graph rejects cycles")
 var extra: int=game.chain.add_node("poison","hit",3)
 check(game.chain.connect_nodes(4,extra),"free graph accepts a sixth node and new non-slot connection")
 game.chain.restore(build)
 check(not game.chain.restore({"schema":true,"nodes":[],"edges":[]}),"boolean schema is safely rejected without operand errors")
 var bad:=build.duplicate(true);bad.edges.append({"from":4,"to":1})
 check(not game.chain.restore(bad) and game.chain.build()==build,"cyclic import is rejected atomically")
 bad=build.duplicate(true);bad.nodes[0].key="not-a-spell"
 check(not game.chain.restore(bad) and game.chain.build()==build,"unsupported node import preserves existing graph")
 bad=build.duplicate(true);bad.nodes[0].x="not numeric"
 check(not game.chain.restore(bad),"malformed coordinate rejected before UI can crash")
 check(game.chain.restore(JSON.parse_string(JSON.stringify(build))),"JSON export/import round trip")
 await clear_arena()
 var e:=victim()
 var before: float=e.hp
 game.execute_spell("fire",e,24,{"key":"fire"})
 await frames(120)
 check(game.chain.casts>=4 and e.hp<before-100,"primary impact actually executes branching delayed casts and HP damage")
 check(game.chain.fusions>=2 and game.chain.finishers==1,"fire/ice/lightning produces fusion and one run finisher")
 game.chain.reset_runtime()
 var pending_before: int=game.chain.pending.size()
 game.execute_spell("fire",e,24,{"key":"fire"})
 check(game.chain.pending.size()>pending_before,"chain uses pending event scheduling")
 game.chain.remove_node(2)
 var count_before: int=game.chain.casts
 await frames(60)
 check(game.chain.casts==count_before,"deleting a queued node safely cancels its cast")
 game.chain.restore(build)
 game.chain.reset_runtime()
 game.execute_spell("fire",e,24,{"key":"fire"})
 game.toggle_pause()
 var clock_before: float=game.chain.clock
 var frozen_hp: float=e.hp
 await frames(30)
 check(game.chain.clock==clock_before and e.hp==frozen_hp,"pause freezes graph clock and deferred damage")
 game.toggle_pause()
 game.chain.pending.clear()
 var run_context: Dictionary={"count":0,"elements":["fire"],"finisher":false}
 for i in 500:game.chain.schedule_children(game.chain.find(1),e,{"element":"fire"},run_context,0,1,"fire")
 check(game.chain.pending.size()<=240 and run_context.count<=240 and game.chain.skipped>0,"single-run event and queue limits enforced")
 game.chain.pending.clear()
 for i in 500:game.chain.schedule_children(game.chain.find(1),e,{"element":"fire"},{"count":0,"elements":["fire"],"finisher":false},0,1,"fire")
 check(game.chain.pending.size()<=400,"global pending limit survives many independent runs")
 var deep: Dictionary={"schema":1,"nodes":[],"edges":[]}
 for i in 21:
  deep.nodes.append({"id":i+1,"key":"fire","gem":"split","quality":1,"x":0,"y":0})
  if i>0:deep.edges.append({"from":i,"to":i+1})
 game.chain.restore(deep)
 var depth_casts: int=game.chain.casts
 game.execute_spell("fire",e,24,{"key":"fire"})
 await frames(900)
 check(game.chain.casts-depth_casts==16,"deep acyclic graph executes only sixteen downstream layers")
 game.chain.restore(build)
 await clear_arena()
 var poison:=victim()
 game.execute_spell("poison",poison,17,{"key":"poison"})
 var poisoned_hp: float=poison.hp
 await frames(40)
 check(poison.hp<poisoned_hp,"poison ticks cause real damage without recursively refreshing status")
 var near:=victim();near.position=poison.position+Vector2(30,0)
 var near_hp: float=near.hp
 game.execute_spell("meteor",poison,44,{"key":"meteor"})
 check(near.hp<near_hp,"meteor damages a second target in its radius")
 await clear_arena()
 var shaman:=victim(3);shaman.position=game.CENTER+Vector2(140,0);shaman.speed=33
 var swift:=victim(1);swift.position=game.CENTER+Vector2(450,0);swift.speed=68
 var armored:=victim(2);armored.position=game.CENTER+Vector2(200,50)
 await frames(30)
 check(shaman.intent=="kite" and shaman.position.distance_to(game.CENTER)>140,"shaman kites away at close range")
 check(swift.charge_cooldown>0,"swift enemy initiates bounded charge cooldown")
 armored.tactical_clock=0
 await frames(40)
 check(armored.shield>0,"armored telegraph grants ward after delay")
 await clear_arena()
 game.wave=4
 var boss: Node2D=game.spawn_enemy()
 boss.speed=0;boss.damage=0;boss.position=game.CENTER+Vector2(240,0)
 var count: int=game.enemies.get_child_count()
 game.resolver.resolve(boss,boss.max_hp*0.31,"arcane",{})
 check(boss.phase==2 and boss.shield==25 and game.enemies.get_child_count()>count,"boss phase two grants shield and host spawns actual minions")
 game.resolver.resolve(boss,boss.max_hp*0.45,"arcane",{})
 check(boss.phase==3 and boss.shield==45,"boss phase three threshold and shield")
 for i in 10:game.summon_minions(boss,4)
 var minions:=0
 for other in game.enemies.get_children():
  if other.get_meta("summoner",-1)==boss.entity_id:minions+=1
 check(minions<=8,"boss summon cap confirmed against live host entities")
 boss.warning=0;boss.cooldown=0;boss.stunned=0;boss.attacks=0
 await frames(2)
 check(boss.warning>0,"boss attack exposes a visible warning interval")
 var tower_hp: float=game.tower.hp
 await frames(15)
 check(game.tower.hp==tower_hp,"boss cannot strike before warning expires")
 boss.warning=0.01
 await frames(3)
 check(boss.attacks==1 and game.tower.hp<tower_hp,"boss warning expiration resolves tower attack exactly once")
 await clear_arena()
 var growth:=Growth.new()
 growth.pity=7
 var options: Array=growth.generate()
 check(options.any(func(o):return o.tier=="legendary"),"source legendary pity forces a legendary choice")
 growth.locked=1
 var locked: Dictionary=options[1].duplicate()
 check(growth.reroll() and growth.options[1]==locked,"reroll preserves locked reward")
 check(not growth.reroll(),"reroll token cannot be spent twice")
 check(growth.claim(0) and not growth.claim(0),"reward can only be claimed once")
 game.chain.restore(build)
 game.open_chain()
 var old_nodes: int=game.chain.nodes.size()
 game.graph_editor.action_buttons.Add.pressed.emit()
 check(game.chain.nodes.size()==old_nodes+1,"graph editor Add changes live model")
 game.graph_editor.action_buttons.Undo.pressed.emit()
 check(game.chain.nodes.size()==old_nodes,"graph editor undo restores model")
 game.close_chain()
 check(game.save_system.load_build()!=null,"Done writes build to user storage")
 var imported:=Chain.new()
 check(imported.restore(game.save_system.load_build()) and imported.nodes.size()==old_nodes,"saved build reloads into fresh graph")
 imported.free()
 game.reward_count=1
 game.offer_reward()
 check(game.reward_open and paused,"growth choice pauses combat")
 game.choose_reward(0)
 check(not game.reward_open and not paused,"choosing reward resumes prior running state")
 var result: Dictionary={"engine":Engine.get_version_info().string,"checks":checks,"failures":failures}
 print("MODULE_RESULT "+JSON.stringify(result))
 paused=false
 quit(0 if failures.is_empty() else 1)
