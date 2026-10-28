extends Node2D
signal died(enemy: Node2D)
signal attacked(amount: float)
signal hit_received(enemy: Node2D, result: Dictionary)
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
var entity_id := 0
var brain: RefCounted
var resolver: Node
var intent := "advance"
var think_clock := 0.0
var charge_time := 0.0
var charge_cooldown := 0.0
var shield := 0.0
var haste := 0.0
var poison_time := 0.0
var poison_clock := 0.0
var tactical_clock := 2.0
var telegraph := 0.0
var art: Sprite2D
const SHEETS = [preload("res://assets/legacy/walk_grunt.webp"), preload("res://assets/legacy/walk_swift.webp"), preload("res://assets/legacy/walk_armored.webp"), preload("res://assets/legacy/walk_shaman.webp"), preload("res://assets/legacy/walk_elite.webp"), preload("res://assets/legacy/walk_boss.webp")]
func _ready() -> void:
 art = Sprite2D.new()
 art.texture = SHEETS[kind]
 art.hframes = 8
 art.scale = Vector2.ONE * (0.75 if kind == 5 else 0.43)
 art.position.y = -30 if kind == 5 else -18
 add_child(art)
func _physics_process(delta: float) -> void:
 if dead:
  return
 slow_time = maxf(0.0, slow_time - delta)
 haste = maxf(0, haste - delta)
 walk_time += delta
 art.frame = int(walk_time * 10.0) % 8
 art.flip_h = target.x < position.x
 if poison_time > 0:
  poison_time = maxf(0, poison_time - delta)
  poison_clock -= delta
  if poison_clock <= 0 and is_instance_valid(resolver):
   poison_clock = 0.5
   resolver.resolve(self, 3.0, "poison", {"status_tick":true})
   if dead:
    return
 if kind == 5:
  queue_redraw()
  return
 var distance := position.distance_to(target)
 var direction: Vector2 = brain.velocity(self, delta) if brain != null else (target - position).normalized()
 if distance > 62 or kind == 3:
  position += direction * speed * (0.5 if slow_time > 0 else 1.0) * (1.4 if haste > 0 else 1.0) * delta
 attack_clock -= delta
 if ((kind == 3 and distance < 330) or distance <= 62) and attack_clock <= 0:
  attack_clock = 2.8 if kind == 3 else 1.2
  attacked.emit(damage)
 if kind in [2, 3, 4]:
  tactical_clock -= delta
  if telegraph > 0:
   telegraph = maxf(0, telegraph - delta)
   if telegraph <= 0:
    if kind == 2:
     shield = maxf(shield, max_hp * 0.12)
    elif brain != null:
     for other in brain.neighbors(self):
      if kind == 3:
       other.hp = minf(other.max_hp, other.hp + other.max_hp * 0.1)
      else:
       other.haste = maxf(other.haste, 1.2)
  elif tactical_clock <= 0 and distance < 370:
   telegraph = 0.55
   tactical_clock = 11.0 if kind == 2 else 9.0
 queue_redraw()
func take_damage(amount: float, element: StringName = &"fire") -> void:
 if is_instance_valid(resolver):
  resolver.resolve(self, amount, String(element))
 else:
  apply_hit(amount, String(element))
func apply_hit(amount: float, element: String, context: Dictionary = {}) -> Dictionary:
 if dead:
  return {}
 var absorbed := minf(shield, maxf(0, amount))
 shield -= absorbed
 var actual := minf(hp, maxf(0, amount - absorbed))
 hp -= actual
 if element == "ice":
  slow_time = maxf(slow_time, 1.8)
 if element == "poison" and not context.get("status_tick", false):
  poison_time = 2.5
 var result := {"damage":actual,"absorbed":absorbed,"killed":hp <= 0,"target_id":entity_id,"position":position,"element":element,"critical":context.get("critical",false)}
 if hp <= 0:
  dead = true
  died.emit(self)
  queue_free()
 hit_received.emit(self, result)
 return result
func _draw() -> void:
 draw_line(Vector2(-20, -54), Vector2(20, -54), Color("25293e"), 4)
 draw_line(Vector2(-20, -54), Vector2(-20 + 40 * hp / maxf(1, max_hp), -54), Color("ed977d"), 4)
 if shield > 0:
  draw_arc(Vector2(0,-18), 32, 0, TAU, 24, Color("81dcea"), 2)
 if telegraph > 0:
  draw_arc(Vector2.ZERO, 42, 0, TAU, 24, Color("f5b677"), 2)
