extends Node2D
const Arena = preload("res://modules/arena/arena.gd")
const Tower = preload("res://modules/tower/tower.gd")
const Enemy = preload("res://modules/enemy/enemy.gd")
const Projectile = preload("res://modules/spell/projectile.gd")
const CombatFX = preload("res://modules/combat_fx/combat_fx.gd")
const HUD = preload("res://modules/ui/hud.gd")
const Steering = preload("res://modules/enemy/steering.gd")
const Boss = preload("res://modules/boss/boss.gd")
const Resolver = preload("res://modules/spell/combat_resolver.gd")
const Chain = preload("res://modules/chain_graph/chain_graph.gd")
const ChainEditor = preload("res://modules/ui/chain_editor.gd")
const Progression = preload("res://modules/progression/progression.gd")
const SaveSystem = preload("res://modules/save_system/save_system.gd")
const Audio = preload("res://modules/audio/audio.gd")
const Catalog = preload("res://modules/spell/catalog.gd")
const CENTER := Vector2(640, 360)
const MAX_ENEMIES := 100
const MAX_PROJECTILES := 64
var brain := Steering.new()
var resolver: Node
var chain: Node
var progression := Progression.new()
var save_system := SaveSystem.new()
var audio: Node
var graph_editor: PanelContainer
var reward_panel: PanelContainer
var reward_choices: HBoxContainer
var reward_reroll: Button
var reward_label: Label
var reward_open := false
var reward_count := 0
var wave_population := {}
var cleared := {}
var boss_wave := 0
var next_entity_id := 1
var total_damage := 0.0
var tower: Node2D
var enemies: Node2D
var projectiles: Node2D
var fx: Node2D
var hud: CanvasLayer
var wave := 0
var kills := 0
var remaining := 0
var spawn_clock := 0.0
var attack_clock := 0.0
var intermission := 2.0
var selected: StringName = &"fire"
var over := false
var paused := false
var speed := 1.0
var impact_count := 0
var rng := RandomNumberGenerator.new()
var web_debug := false
var debug_clock := 0.0

func _ready() -> void:
 rng.seed = 3201
 if OS.has_feature("web"):
  web_debug = bool(JavaScriptBridge.eval("new URLSearchParams(location.search).get('debug') === '1'"))
 resolver=Resolver.new()
 add_child(resolver)
 chain=Chain.new()
 chain.host=self
 add_child(chain)
 var saved: Variant=save_system.load_build()
 if saved!=null:
  chain.restore(saved)
 chain.cast_requested.connect(execute_spell)
 chain.reaction_activated.connect(func(at:Vector2):fx.impact(at,&"arcane"))
 resolver.hit_resolved.connect(on_resolved)
 audio=Audio.new()
 add_child(audio)
 add_child(Arena.new())
 enemies = Node2D.new()
 enemies.name = "Enemies"
 enemies.y_sort_enabled = true
 add_child(enemies)
 tower = Tower.new()
 tower.position = CENTER
 add_child(tower)
 projectiles = Node2D.new()
 add_child(projectiles)
 fx = CombatFX.new()
 add_child(fx)
 hud = HUD.new()
 hud.process_mode = Node.PROCESS_MODE_ALWAYS
 add_child(hud)
 set_process(false)
 hud.diagnostic_tick.connect(_process)
 hud.chain_requested.connect(open_chain)
 hud.audio_requested.connect(func():audio.muted=not audio.muted;hud.buttons["Audio: off"].text="Audio: off" if audio.muted else "Audio: on")
 graph_editor=ChainEditor.new()
 hud.root.add_child(graph_editor)
 graph_editor.setup(chain)
 chain.changed.connect(publish_debug)
 graph_editor.hide()
 graph_editor.closed.connect(close_chain)
 create_rewards()
 hud.pause_requested.connect(toggle_pause)
 hud.speed_requested.connect(cycle_speed)
 hud.wave_requested.connect(start_wave)
 hud.restart_requested.connect(restart)
 hud.element_selected.connect(func(element: StringName): selected = element)
 tower.health_changed.connect(func(_current: float, _maximum: float): refresh_hud())
 tower.destroyed.connect(game_over)
 refresh_hud()

func _physics_process(delta: float) -> void:
 if over:
  return
 brain.prepare(enemies.get_children())
 attack_clock -= delta
 if remaining > 0:
  spawn_clock -= delta
  if spawn_clock <= 0.0 and enemies.get_child_count() < MAX_ENEMIES:
   spawn_enemy()
   remaining -= 1
   spawn_clock = maxf(0.25, 0.85 - wave * 0.025)
 elif enemies.get_child_count() == 0:
  intermission -= delta
  if intermission <= 0.0:
   start_wave()
 if attack_clock <= 0.0:
  var target := nearest_enemy()
  if target != null and projectiles.get_child_count() < MAX_PROJECTILES:
   var shot := Projectile.new()
   shot.position = CENTER + Vector2(0, -55)
   shot.target = target
   shot.element = selected
   shot.power = Catalog.power(String(selected))*progression.multiplier(String(selected))*chain.root_boost(String(selected))
   shot.context={"key":String(selected)}
   shot.execute_requested.connect(execute_spell)
   shot.impacted.connect(on_impact)
   projectiles.add_child(shot)
   attack_clock = 0.45
 refresh_hud()

func start_wave() -> void:
 # Early wave is allowed while survivors remain, after all current spawns issued.
 if over or paused or reward_open or graph_editor.visible or remaining > 0:
  return
 wave += 1
 remaining = 8 + wave * 3
 spawn_clock = 0.0
 intermission = 6.0
 refresh_hud()

func spawn_enemy(force_kind: int = -1) -> Node2D:
 var is_boss := force_kind<0 and wave>0 and wave%4==0 and boss_wave!=wave
 var enemy = Boss.new() if is_boss else Enemy.new()
 if is_boss:
  boss_wave=wave
  enemy.boss_kind=(int(wave/4)-1)%3
  enemy.summon_requested.connect(summon_minions)
 else:
  enemy.kind=force_kind if force_kind>=0 else (wave+remaining)%(5 if wave>=3 else 4 if wave>=2 else 3)
 enemy.entity_id=next_entity_id
 next_entity_id+=1
 enemy.brain=brain
 enemy.resolver=resolver
 enemy.set_meta("wave",wave)
 wave_population[wave]=int(wave_population.get(wave,0))+1
 var angle := rng.randf_range(0.0, TAU)
 enemy.position = CENTER + Vector2(cos(angle) * 560.0, sin(angle) * 245.0)
 enemy.target = CENTER
 enemy.max_hp = [43.5, 30.0, 70.0, 48.0, 140.0, 700.0][enemy.kind] + wave * (50 if is_boss else 5.0)
 enemy.hp = enemy.max_hp
 enemy.speed = [40.0, 68.0, 29.0, 33.0, 36.0, 24.0][enemy.kind] + wave
 enemy.damage = 4.0 + wave
 enemy.died.connect(on_enemy_died)
 enemy.attacked.connect(func(amount: float): tower.take_damage(amount))
 enemies.add_child(enemy)
 return enemy

func nearest_enemy() -> Node2D:
 var nearest: Node2D = null
 var distance := INF
 for enemy in enemies.get_children():
  if enemy.dead:
   continue
  var d: float = enemy.position.distance_squared_to(CENTER)
  if d < distance:
   nearest = enemy
   distance = d
 return nearest

func on_impact(at: Vector2, element: StringName) -> void:
 impact_count += 1
 fx.impact(at, element)

func on_enemy_died(enemy: Node2D) -> void:
 kills += 1
 var origin_wave: int=enemy.get_meta("wave",0)
 wave_population[origin_wave]=maxi(0,int(wave_population.get(origin_wave,1))-1)
 if origin_wave>0 and origin_wave%3==0 and wave_population[origin_wave]==0 and (origin_wave<wave or remaining==0) and not cleared.has(origin_wave):
  cleared[origin_wave]=true
  reward_count+=1
  call_deferred("offer_reward")

func toggle_pause() -> void:
 if over or reward_open or graph_editor.visible:
  return
 paused = not paused
 get_tree().paused = paused
 hud.pause_button.text = "Resume" if paused else "Pause"
 refresh_hud()
 if web_debug:
  JavaScriptBridge.eval("window.SG_M1_STATE.paused = " + JSON.stringify(paused))

func cycle_speed() -> void:
 if over or reward_open or graph_editor.visible:
  return
 speed = 2.0 if speed == 1.0 else 1.0
 Engine.time_scale = speed
 hud.speed_button.text = "%dx" % int(speed)
 if web_debug:
  JavaScriptBridge.eval("window.SG_M1_STATE.speed = " + JSON.stringify(speed))

func game_over() -> void:
 over = true
 get_tree().paused = true
 hud.message.text = "The crystal has fallen — Restart to defend again."
 hud.wave_button.disabled = true

func restart() -> void:
 get_tree().paused = false
 Engine.time_scale = 1.0
 get_tree().call_deferred("reload_current_scene")

func refresh_hud() -> void:
 hud.update_status(wave, kills, tower.hp, selected)
 hud.wave_button.disabled = over or paused or reward_open or graph_editor.visible or remaining > 0
 var boss := enemies.get_children().filter(func(e):return e.kind==5 and not e.dead)
 hud.boss_status.text="" if boss.is_empty() else "%s • Phase %d • HP %d / %d • %s" % [["Crystal King","Nightmare","Star Colossus"][boss[0].boss_kind],boss[0].phase,boss[0].hp,boss[0].max_hp,"WARNING" if boss[0].warning>0 else ""]
 if not over:
  hud.message.text = "Paused" if paused else ("Next wave available • Survivors remain" if remaining == 0 and enemies.get_child_count() > 0 else "Defend the crystal • Select a spell below")

func _notification(what: int) -> void:
 if what == NOTIFICATION_APPLICATION_FOCUS_OUT and is_instance_valid(hud) and not paused and not over and not reward_open and (not is_instance_valid(graph_editor) or not graph_editor.visible):
  toggle_pause()

# Optional read-only browser diagnostics, enabled only with ?debug=1.
func _process(delta: float) -> void:
 if not web_debug:
  return
 debug_clock -= delta
 if debug_clock <= 0.0:
  debug_clock = 0.25
  var state := {"wave": wave, "kills": kills, "hp": tower.hp, "enemies": enemies.get_child_count(), "shots": projectiles.get_child_count(), "paused": paused, "speed": speed, "element": String(selected), "over": over, "chain_casts":chain.casts,"fusions":chain.fusions,"finishers":chain.finishers,"nodes":chain.nodes.size(),"graph_open":graph_editor.visible,"reward_open":reward_open,"damage":total_damage,"fps":Engine.get_frames_per_second()}
  var bounds := {}
  var debug_buttons: Dictionary=hud.buttons.duplicate()
  if graph_editor.visible:
   for key in graph_editor.action_buttons:debug_buttons[key]=graph_editor.action_buttons[key]
  for key in debug_buttons:
   var rect: Rect2 = debug_buttons[key].get_global_rect()
   bounds[key] = [rect.get_center().x, rect.get_center().y, rect.size.x, rect.size.y]
  state["buttons"] = bounds
  state["viewport"] = [get_viewport_rect().size.x, get_viewport_rect().size.y]
  JavaScriptBridge.eval("window.SG_M1_STATE = " + JSON.stringify(state))


func execute_spell(key: String, target: Node2D, power: float, context: Dictionary = {}) -> void:
 if not is_instance_valid(target) or target.dead:return
 if context.get("chain",false):power*=progression.multiplier(key)
 var origin: Vector2=target.position
 var element:=Catalog.element(key)
 var victims: Array=[target]
 var all: Array=enemies.get_children().filter(func(e):return not e.dead)
 if key in ["fire","meteor","nova"]:
  var radius:=145.0 if key=="meteor" else 90.0 if key=="nova" else 35.0
  victims=all.filter(func(e):return e.position.distance_to(origin)<radius).slice(0,24)
 elif key=="lightning":
  victims=all.filter(func(e):return e.position.distance_to(origin)<165).slice(0,3)
 elif key=="beam":
  var axis: Vector2=(origin-CENTER).normalized()
  victims=all.filter(func(e):return absf(axis.cross(e.position-CENTER))<28 and axis.dot(e.position-CENTER)>0).slice(0,8)
 var ctx:=context.duplicate(false)
 ctx["key"]=key
 for victim in victims:
  if not is_instance_valid(victim) or victim.dead:continue
  resolver.resolve(victim,power,element,ctx)
 fx.impact(origin,StringName(element) if element in ["fire","ice","lightning","arcane"] else &"arcane")
 audio.cue(element)

func on_resolved(enemy: Node2D, result: Dictionary, context: Dictionary) -> void:
 total_damage+=float(result.damage)
 if context.get("status_tick",false):return
 if context.get("chain",false):chain.on_chain_hit(enemy,result,context)
 else:chain.on_primary(enemy,result,str(context.get("key",result.element)))

func summon_minions(boss: Node2D, count: int) -> void:
 # Host confirms actual living minions, capped per boss and globally.
 var living:=0
 for e in enemies.get_children():
  if not e.dead and int(e.get_meta("summoner",-1))==boss.entity_id:living+=1
 for i in mini(count,8-living):
  if enemies.get_child_count()>=MAX_ENEMIES:break
  var minion:=spawn_enemy(0)
  var origin_wave: int=boss.get_meta("wave",wave)
  if origin_wave!=wave:
   wave_population[wave]=int(wave_population.get(wave,1))-1
   wave_population[origin_wave]=int(wave_population.get(origin_wave,0))+1
   minion.set_meta("wave",origin_wave)
  minion.set_meta("summoner",boss.entity_id)
  minion.position=boss.position+Vector2.from_angle(float(i)*TAU/3)*60

func open_chain() -> void:
 if over or reward_open:return
 for child in hud.root.get_children():
  if child is VBoxContainer:child.hide()
 graph_editor.show()
 get_tree().paused=true
 refresh_hud()
 publish_debug()

func close_chain() -> void:
 var saved: bool=save_system.save_build(chain.build())
 graph_editor.hide()
 for child in hud.root.get_children():
  if child is VBoxContainer:child.show()
 get_tree().paused=paused
 if not saved:hud.message.text="Build save failed; export JSON to keep a backup."
 publish_debug()
 if reward_count>0:call_deferred("offer_reward")

func create_rewards() -> void:
 reward_panel=PanelContainer.new()
 reward_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
 reward_panel.offset_left=-360;reward_panel.offset_right=360
 reward_panel.offset_top=-150;reward_panel.offset_bottom=150
 hud.root.add_child(reward_panel)
 var box:=VBoxContainer.new();reward_panel.add_child(box)
 reward_label=Label.new();box.add_child(reward_label)
 reward_choices=HBoxContainer.new();box.add_child(reward_choices)
 reward_reroll=Button.new();reward_reroll.text="Reroll (1)";reward_reroll.custom_minimum_size.y=48;box.add_child(reward_reroll)
 reward_reroll.pressed.connect(func():if progression.reroll():render_rewards())
 reward_panel.hide()

func offer_reward() -> void:
 if over or reward_open or graph_editor.visible or reward_count<=0:return
 reward_open=true
 progression.locked=-1
 progression.generate()
 render_rewards()
 reward_panel.show()
 get_tree().paused=true
 publish_debug()

func render_rewards() -> void:
 reward_label.text="GROWTH • Choose one • Legendary pity %d / 7" % progression.pity
 for node in reward_choices.get_children():
  reward_choices.remove_child(node);node.queue_free()
 for i in progression.options.size():
  var option: Dictionary=progression.options[i]
  var column:=VBoxContainer.new();reward_choices.add_child(column)
  var button:=Button.new();button.text=str(option.key)+" +"+str(option.power)+"\n"+str(option.tier);button.custom_minimum_size=Vector2(210,100);column.add_child(button)
  button.pressed.connect(func():choose_reward(i))
  var lock:=Button.new();lock.text="Locked" if progression.locked==i else "Lock";lock.custom_minimum_size.y=48;column.add_child(lock)
  lock.pressed.connect(func():progression.locked=-1 if progression.locked==i else i;render_rewards())
 reward_reroll.disabled=progression.rerolls<=0

func choose_reward(index: int) -> void:
 if not reward_open or not progression.claim(index):return
 reward_count-=1
 reward_open=false
 reward_panel.hide()
 get_tree().paused=paused
 publish_debug()
 if reward_count>0:call_deferred("offer_reward")

func publish_debug() -> void:
 if web_debug:
  debug_clock=0
  _process(0)
