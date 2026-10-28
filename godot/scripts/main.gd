extends Node2D
const Arena = preload("res://modules/arena/arena.gd")
const Tower = preload("res://modules/tower/tower.gd")
const Enemy = preload("res://modules/enemy/enemy.gd")
const Projectile = preload("res://modules/spell/projectile.gd")
const CombatFX = preload("res://modules/combat_fx/combat_fx.gd")
const HUD = preload("res://modules/ui/hud.gd")
const CENTER := Vector2(640, 360)
const MAX_ENEMIES := 100
const MAX_PROJECTILES := 64
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
   shot.power = 24.0 if selected != &"lightning" else 20.0
   shot.impacted.connect(on_impact)
   projectiles.add_child(shot)
   attack_clock = 0.45
 refresh_hud()

func start_wave() -> void:
 # Early wave is allowed while survivors remain, after all current spawns issued.
 if over or paused or remaining > 0:
  return
 wave += 1
 remaining = 8 + wave * 3
 spawn_clock = 0.0
 intermission = 6.0
 refresh_hud()

func spawn_enemy() -> Node2D:
 var enemy := Enemy.new()
 enemy.kind = (wave + remaining) % 3
 var angle := rng.randf_range(0.0, TAU)
 enemy.position = CENTER + Vector2(cos(angle) * 560.0, sin(angle) * 245.0)
 enemy.target = CENTER
 enemy.max_hp = [43.5, 30.0, 70.0][enemy.kind] + wave * 5.0
 enemy.hp = enemy.max_hp
 enemy.speed = [40.0, 68.0, 29.0][enemy.kind] + wave
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

func on_enemy_died(_enemy: Node2D) -> void:
 kills += 1

func toggle_pause() -> void:
 if over:
  return
 paused = not paused
 get_tree().paused = paused
 hud.pause_button.text = "Resume" if paused else "Pause"
 refresh_hud()
 if web_debug:
  JavaScriptBridge.eval("window.SG_M1_STATE.paused = " + JSON.stringify(paused))

func cycle_speed() -> void:
 if over:
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
 hud.wave_button.disabled = over or paused or remaining > 0
 if not over:
  hud.message.text = "Paused" if paused else ("Next wave available • Survivors remain" if remaining == 0 and enemies.get_child_count() > 0 else "Defend the crystal • Select a spell below")

func _notification(what: int) -> void:
 if what == NOTIFICATION_APPLICATION_FOCUS_OUT and is_instance_valid(hud) and not paused and not over:
  toggle_pause()

# Optional read-only browser diagnostics, enabled only with ?debug=1.
func _process(delta: float) -> void:
 if not web_debug:
  return
 debug_clock -= delta
 if debug_clock <= 0.0:
  debug_clock = 0.25
  var state := {"wave": wave, "kills": kills, "hp": tower.hp, "enemies": enemies.get_child_count(), "shots": projectiles.get_child_count(), "paused": paused, "speed": speed, "element": String(selected), "over": over}
  var bounds := {}
  for key in hud.buttons:
   var rect: Rect2 = hud.buttons[key].get_global_rect()
   bounds[key] = [rect.get_center().x, rect.get_center().y, rect.size.x, rect.size.y]
  state["buttons"] = bounds
  state["viewport"] = [get_viewport_rect().size.x, get_viewport_rect().size.y]
  JavaScriptBridge.eval("window.SG_M1_STATE = " + JSON.stringify(state))
