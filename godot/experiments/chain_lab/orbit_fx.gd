extends Node2D
## Finite cast illustration only: no collision, targets or damage callbacks.
const RUNE=preload("res://experiments/chain_lab/assets/orbit.svg")
const ORB=preload("res://experiments/chain_lab/assets/orbit_orb.svg")
const LIFETIME=0.9
var age:=0.0
var rune: Sprite2D
var orbs: Array[Sprite2D]=[]
func _ready() -> void:
 set_meta("spell_key","orbit")
 rune=Sprite2D.new();rune.texture=RUNE;rune.scale=Vector2(150.0/256.0,110.0/192.0);add_child(rune)
 for i in range(5):
  var orb:=Sprite2D.new();orb.texture=ORB;orb.scale=Vector2.ONE*0.45;add_child(orb);orbs.append(orb)
 update_pose()
func update_pose() -> void:
 rune.rotation=age*3.0
 for i in orbs.size():
  var angle: float=i*TAU/5.0+age*7.0
  orbs[i].position=Vector2(cos(angle)*60.0,sin(angle)*35.0)
  orbs[i].rotation=angle
 modulate.a=1.0-smoothstep(0.45,LIFETIME,age)
func _process(delta: float) -> void:
 age+=maxf(delta,0.0)
 if age>=LIFETIME:queue_free();return
 update_pose()
