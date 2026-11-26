extends Node2D
## Finite cast illustration only: no collision, targets or damage callbacks.
const RUNE=preload("res://experiments/chain_lab/assets/orbit.svg")
const ORB=preload("res://experiments/chain_lab/assets/orbit_orb.svg")
const LIFETIME=0.9
var age:=0.0
var rune: Sprite2D
var orbs: Array[Sprite2D]=[]
var phases: Array[float]=[]
var directions: Array[Vector2]=[]
func _ready() -> void:
 set_meta("spell_key","orbit")
 rune=Sprite2D.new();rune.texture=RUNE;rune.scale=Vector2(150.0/256.0,110.0/192.0);add_child(rune)
 for i in range(5):
  var phase: float=i*TAU/5.0;phases.append(phase);directions.append(Vector2(cos(phase),sin(phase)))
  var orb:=Sprite2D.new();orb.texture=ORB;orb.scale=Vector2.ONE*0.45;add_child(orb);orbs.append(orb)
 update_pose()
func update_pose() -> void:
 rune.rotation=age*3.0
 var angle:=age*7.0
 var axis_x:=Vector2(cos(angle),sin(angle))
 var axis_y:=Vector2(-axis_x.y,axis_x.x)
 for i in orbs.size():
  var radial: Vector2=axis_x*directions[i].x+axis_y*directions[i].y
  orbs[i].position=Vector2(radial.x*60.0,radial.y*35.0)
  orbs[i].rotation=phases[i]+angle
 modulate.a=1.0-smoothstep(0.45,LIFETIME,age)
func _process(delta: float) -> void:
 age+=maxf(delta,0.0)
 if age>=LIFETIME:queue_free();return
 update_pose()
