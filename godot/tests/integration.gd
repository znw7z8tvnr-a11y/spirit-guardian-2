extends SceneTree
var failures: Array[String] = []
var checks: Array[String] = []
func _initialize() -> void:
 call_deferred("run")
func check(condition: bool, description: String) -> void:
 if condition:
  checks.append(description)
 else:
  failures.append(description)
func frames(count: int) -> void:
 for i in count:
  await physics_frame
func run() -> void:
 var game = load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 current_scene = game
 await frames(2)
 check(game.tower.hp == 100, "tower starts at 100 HP")
 game.intermission = 999
 game.start_wave()
 check(game.wave == 1 and game.remaining == 11, "first wave schedules 11 enemies")
 await frames(180)
 check(game.enemies.get_child_count() > 0, "real physics loop spawns enemies")
 var enemy = game.enemies.get_child(0)
 enemy.hp = 100000.0
 enemy.max_hp = 100000.0
 var before: Vector2 = enemy.position
 await frames(60)
 check(enemy.position.distance_to(game.CENTER) < before.distance_to(game.CENTER), "AI moves toward tower")
 game.hud.pause_button.pressed.emit()
 before = enemy.position
 await frames(30)
 check(enemy.position == before, "pause freezes enemy simulation")
 game.hud.pause_button.pressed.emit()
 game.hud.speed_button.pressed.emit()
 check(Engine.time_scale == 2.0, "speed control sets engine scale")
 game.hud.speed_button.pressed.emit()
 # Isolate projectile behavior from the wave schedule and from other targets.
 game.remaining = 0
 for node in game.enemies.get_children():
  node.queue_free()
 for node in game.projectiles.get_children():
  node.queue_free()
 await frames(2)
 for element in [&"fire", &"ice", &"lightning", &"arcane"]:
  game.selected = element
  var victim = game.spawn_enemy()
  victim.position = game.CENTER + Vector2(150, 0)
  victim.speed = 0
  victim.hp = 10
  var kills_before: int = game.kills
  await frames(100)
  check(game.kills == kills_before + 1, "%s projectile hits and kills through physics" % element)
 # Ice status must change movement, not merely change its appearance.
 var slow = game.spawn_enemy()
 slow.position = game.CENTER + Vector2(400, 0)
 slow.speed = 60
 slow.take_damage(1, &"ice")
 game.attack_clock = 999
 var slow_before: Vector2 = slow.position
 await frames(30)
 check(slow.slow_time > 0 and slow_before.distance_to(slow.position) < 20, "ice status slows movement")
 slow.position = game.CENTER + Vector2(60, 0)
 var hp_before: float = game.tower.hp
 await frames(90)
 check(game.tower.hp < hp_before, "enemy melee damages tower HP")
 game.remaining = 1
 var wave_before: int = game.wave
 game.start_wave()
 check(game.wave == wave_before, "early wave cannot discard unspawned enemies")
 game.remaining = 0
 game.start_wave()
 check(game.wave == wave_before + 1, "early wave preserves living survivors")
 game.tower.take_damage(10000)
 check(game.over and paused, "zero HP enters game over and freezes combat")
 game.hud.restart_requested.emit()
 await frames(3)
 game = current_scene
 check(not game.over and game.tower.hp == 100 and not paused and Engine.time_scale == 1, "restart reloads clean game and time scale")
 # Normal unmodified scene soak, driven by real engine ticks.
 await frames(3600)
 check(game.wave > 0 and game.kills > 0, "60 simulated seconds: normal loop spawns, casts and scores")
 check(game.enemies.get_child_count() <= 100 and game.projectiles.get_child_count() <= 64, "entity caps remain bounded")
 var result := {"engine": Engine.get_version_info().string, "checks": checks, "failures": failures, "soak": {"wave":game.wave,"kills":game.kills,"hp":game.tower.hp,"enemies":game.enemies.get_child_count(),"projectiles":game.projectiles.get_child_count(),"over":game.over}}
 print("INTEGRATION_RESULT " + JSON.stringify(result))
 var file := FileAccess.open("user://integration-result.json", FileAccess.WRITE)
 file.store_string(JSON.stringify(result, "  "))
 paused = false
 quit(0 if failures.is_empty() else 1)
