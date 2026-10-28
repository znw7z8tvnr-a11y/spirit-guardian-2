extends Node2D
signal died(enemy: Node2D)
signal attacked(amount: float)
var hp := 45.0
var max_hp := 45.0
var speed := 45.0
var damage := 6.0
var target := Vector2.ZERO
var attack_clock := 0.0
var slow_time := 0.0
var walk_time := 0.0
var dead := false
var kind := 0
var art: Sprite2D
const SHEETS = [preload("res://assets/legacy/walk_grunt.webp"), preload("res://assets/legacy/walk_swift.webp"), preload("res://assets/legacy/walk_armored.webp")]

func _ready() -> void:
 art = Sprite2D.new()
 art.texture = SHEETS[kind]
 art.hframes = 8
 art.scale = Vector2.ONE * 0.43
 art.position.y = -18
 add_child(art)

func _physics_process(delta: float) -> void:
 if dead:
  return
 slow_time = maxf(0.0, slow_time - delta)
 walk_time += delta
 var distance := position.distance_to(target)
 if distance > 62.0:
  position = position.move_toward(target, speed * (0.5 if slow_time > 0 else 1.0) * delta)
  art.frame = int(walk_time * 10.0) % 8
  art.flip_h = target.x < position.x
 else:
  attack_clock -= delta
  art.scale = Vector2.ONE * (0.43 + 0.035 * sin(walk_time * 12.0))
  if attack_clock <= 0.0:
   attack_clock = 1.2
   attacked.emit(damage)
 queue_redraw()

func take_damage(amount: float, element: StringName = &"fire") -> void:
 if dead:
  return
 hp = maxf(0.0, hp - maxf(amount, 0.0))
 if element == &"ice":
  slow_time = 1.8
 if hp <= 0.0:
  dead = true
  died.emit(self)
  queue_free()

func _draw() -> void:
 draw_line(Vector2(-20, -54), Vector2(20, -54), Color("25293e"), 4)
 draw_line(Vector2(-20, -54), Vector2(-20 + 40 * hp / max_hp, -54), Color("ed977d"), 4)
