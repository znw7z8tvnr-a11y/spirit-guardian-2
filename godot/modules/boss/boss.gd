extends "res://modules/enemy/enemy.gd"
signal phase_changed(phase: int)
signal summon_requested(boss: Node2D, count: int)
const Catalog = preload("res://modules/spell/catalog.gd")
const MOVES := [["crystalSpear","fracture","summon","crystalStorm","ultimate"],["voidBolt","rift","summon","seal","ultimate"],["starPulse","gravity","summon","meteor","ultimate"]]
const WEAK := ["ice", "light", "lightning"]
var boss_kind := 0
var phase := 1
var cooldown := 3.5
var warning := 0.0
var warning_total := 0.0
var move := ""
var attacks := 0
var recent: Array = []
var stagger_meter := 0.0
var stunned := 0.0
var adaptation := {"chain":0.0,"speed":0.0,"melee":0.0,"ranged":0.0,"element":0.0}
func _init() -> void:
 kind = 5
func _physics_process(delta: float) -> void:
 super._physics_process(delta)
 if dead:
  return
 if position.distance_to(target) > 235:
  position = position.move_toward(target, speed * delta)
 for key in adaptation:
  adaptation[key] = maxf(0, adaptation[key] - delta * 0.25)
 if stunned > 0:
  stunned = maxf(0, stunned - delta)
  return
 if warning > 0:
  warning = maxf(0, warning - delta)
  if warning <= 0:
   strike()
 else:
  cooldown -= delta
  if cooldown <= 0:
   move = choose_move()
   warning_total = float(Catalog.data.MOVE[move].warning)
   warning = warning_total
 queue_redraw()
func choose_move() -> String:
 var choices: Array = MOVES[boss_kind].slice(0, 2 if phase == 1 else 4 if phase == 2 else 5)
 var best := str(choices[0])
 var high := -INF
 for i in choices.size():
  var candidate: String = choices[i]
  var score := float((attacks * 7 + i * 11 + boss_kind * 13) % 17) / 17
  if candidate == move:
   score -= 2
  if candidate in recent:
   score -= 0.6
  if candidate == "ultimate" and phase == 3:
   score += 1.2
  if candidate == "seal" and adaptation.chain > 4:
   score += 2
  if score > high:
   high = score
   best = candidate
 return best
func strike() -> void:
 var spec: Dictionary = Catalog.data.MOVE[move]
 attacks += 1
 recent.append(move)
 if recent.size() > 2:
  recent.pop_front()
 if move == "summon":
  summon_requested.emit(self, 4 if phase == 3 else 3)
 else:
  # Telegraph is centered on the guarded crystal, the target of this single-tower game.
  attacked.emit(roundf(float(spec.damage) * (1 + (phase - 1) * 0.22)))
 cooldown = 3.8 if phase == 3 else 4.8 if phase == 2 else 5.8
func apply_hit(amount: float, element: String, context: Dictionary = {}) -> Dictionary:
 adaptation.chain = minf(20, adaptation.chain + (1 if context.get("chain",false) else 0))
 var result: Dictionary = super.apply_hit(amount * (1.2 if element == WEAK[boss_kind] else 1.0) * (1.4 if stunned > 0 else 1.0), element, context)
 var next := 3 if hp / max_hp <= 0.35 else 2 if hp / max_hp <= 0.7 else 1
 if not dead and next > phase:
  for value in range(phase + 1, next + 1):
   phase = value
   phase_changed.emit(phase)
   if phase == 2:
    summon_requested.emit(self, 3)
  shield = 45 if phase == 3 else 25
  warning = 0
  cooldown = minf(cooldown, 1.3)
 if not dead:
  stagger_meter += minf(20, amount * 0.1)
  if stagger_meter >= 100:
   stagger_meter = 0
   stunned = 1.1 if phase == 3 else 1.4
   warning = 0
 return result
func _draw() -> void:
 super._draw()
 if warning > 0:
  draw_circle(target - position, 90, Color(1,0.2,0.3,0.13))
  draw_arc(target - position, 90, -PI/2, -PI/2 + TAU * (1-warning / warning_total), 48, Color("ff936b"), 4)
