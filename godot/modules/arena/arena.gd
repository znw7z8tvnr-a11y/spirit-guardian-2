extends Node2D
# Background module raster is extracted from the original Canvas cache.
# It is provisional flattened terrain, not final layered 2.5D environment art.
func _ready() -> void:
 var ground := Sprite2D.new()
 ground.texture = preload("res://assets/legacy/terrain.png")
 ground.position = Vector2(640, 360)
 ground.z_index = -10
 add_child(ground)
 var camera := Camera2D.new()
 camera.position = Vector2(640, 360)
 add_child(camera)
