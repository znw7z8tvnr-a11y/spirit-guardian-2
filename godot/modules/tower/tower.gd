extends Node2D
signal health_changed(current: float, maximum: float)
signal destroyed
const MAX_HP := 100.0
var hp := MAX_HP
var art: Sprite2D
var time := 0.0

func _ready() -> void:
 art = Sprite2D.new()
 art.texture = preload("res://assets/legacy/tower_guardian.webp")
 # Prototype nominal footprint 200x210, displayed at 70%.
 # Original active V32 castle is baked into arena; visual parity is unverified.
 art.scale = Vector2(200.0 / 342.0, 210.0 / 360.0) * 0.7
 art.position.y = -42
 add_child(art)

func _process(delta: float) -> void:
 time += delta
 art.position.y = -42 + sin(time * 1.8) * 2.0

func take_damage(amount: float) -> void:
 if hp <= 0.0:
  return
 hp = maxf(0.0, hp - maxf(0.0, amount))
 health_changed.emit(hp, MAX_HP)
 if hp <= 0.0:
  destroyed.emit()

func reset() -> void:
 hp = MAX_HP
 health_changed.emit(hp, MAX_HP)
