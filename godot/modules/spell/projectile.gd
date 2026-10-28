extends Node2D
signal impacted(at: Vector2, element: StringName)
signal execute_requested(key: String, target: Node2D, power: float, context: Dictionary)
var context := {}
var target: Node2D
var element: StringName = &"fire"
var power := 20.0
var life := 2.5
const TEXTURES = {
 &"fire": preload("res://assets/legacy/fireball.webp"),
 &"ice": preload("res://assets/legacy/icebolt.webp"),
 &"lightning": preload("res://assets/legacy/lightning.webp"),
 &"arcane": preload("res://assets/legacy/arcane.webp"),
 &"poison": preload("res://assets/legacy/poison.webp"),
 &"meteor": preload("res://assets/legacy/meteor.webp"),
 &"nova": preload("res://assets/legacy/iceburst.webp"),
 &"beam": preload("res://assets/legacy/arcane.webp")
}
func _ready() -> void:
 var art := Sprite2D.new()
 art.texture = TEXTURES[element]
 art.scale = Vector2.ONE * 0.19
 add_child(art)
func _physics_process(delta: float) -> void:
 life -= delta
 if life <= 0.0 or not is_instance_valid(target) or target.dead:
  queue_free()
  return
 var aim := target.position + Vector2(0, -18)
 rotation = position.angle_to_point(aim)
 position = position.move_toward(aim, 520.0 * delta)
 if position.distance_to(aim) <= 14.0:
  if execute_requested.get_connections().is_empty():
   target.take_damage(power, element)
  else:
   execute_requested.emit(String(element), target, power, context)
  impacted.emit(position, element)
  queue_free()
