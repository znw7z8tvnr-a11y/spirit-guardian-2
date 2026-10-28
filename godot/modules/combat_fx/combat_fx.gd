extends Node2D
const TEXTURES = preload("res://modules/spell/projectile.gd").TEXTURES
const MAX_EFFECTS := 48
func impact(at: Vector2, element: StringName) -> void:
 if get_child_count() >= MAX_EFFECTS:
  return
 var fx := Sprite2D.new()
 fx.texture = TEXTURES[element]
 fx.position = at
 fx.scale = Vector2.ONE * 0.13
 add_child(fx)
 var tween := create_tween().set_parallel(true)
 tween.tween_property(fx, "scale", Vector2.ONE * 0.42, 0.22)
 tween.tween_property(fx, "modulate:a", 0.0, 0.22)
 tween.chain().tween_callback(fx.queue_free)
