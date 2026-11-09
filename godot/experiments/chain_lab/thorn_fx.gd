extends Node2D
## Finite ground eruption; animation has no wall, collision or damage callback.
const ROOTS=preload("res://experiments/chain_lab/assets/thorn.svg")
const SPIKE=preload("res://experiments/chain_lab/assets/thorn_spike.svg")
const LIFETIME=1.0
var age:=0.0
var roots: Sprite2D
var spikes: Array[Sprite2D]=[]
func _ready() -> void:
 set_meta("spell_key","thorn")
 roots=Sprite2D.new();roots.texture=ROOTS;roots.scale=Vector2(150.0/256.0,110.0/192.0);add_child(roots)
 for i in range(8):
  var spike:=Sprite2D.new();spike.texture=SPIKE;spike.offset.y=-64;spike.position=Vector2(cos(i*2.399),sin(i*2.399)*0.65)*(18+(i%4)*14);add_child(spike);spikes.append(spike)
 update_pose()
func update_pose() -> void:
 var height:=smoothstep(0.0,0.22,age)*(1.0-smoothstep(0.45,LIFETIME,age))
 for i in spikes.size():spikes[i].scale=Vector2(0.4+(i%3)*0.06,maxf(0.02,height*(0.5+(i%3)*0.08)))
 modulate.a=1.0-smoothstep(0.55,LIFETIME,age)
func _process(delta: float) -> void:
 age+=maxf(delta,0.0)
 if age>=LIFETIME:queue_free();return
 update_pose()
