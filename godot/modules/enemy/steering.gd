extends RefCounted
# Port of SGEnemyAI10 version 14.final; independent from DOM or Canvas.
const CELL := 74.0
var cells := {}
func prepare(items: Array) -> void:
 cells.clear()
 for enemy in items:
  if enemy.dead:
   continue
  var key := Vector2i(floori(enemy.position.x / CELL), floori(enemy.position.y / CELL))
  if not cells.has(key):
   cells[key] = []
  cells[key].append(enemy)
func neighbors(enemy: Node2D) -> Array:
 var key := Vector2i(floori(enemy.position.x / CELL), floori(enemy.position.y / CELL))
 var result := []
 for y in range(-1, 2):
  for x in range(-1, 2):
   for other in cells.get(key + Vector2i(x, y), []):
    if is_instance_valid(other) and other != enemy and not other.dead:
     result.append(other)
 return result
func velocity(enemy: Node2D, delta: float) -> Vector2:
 enemy.think_clock -= delta
 enemy.charge_time = maxf(0, enemy.charge_time - delta)
 enemy.charge_cooldown = maxf(0, enemy.charge_cooldown - delta)
 var toward: Vector2 = (enemy.target - enemy.position).normalized()
 var distance: float = enemy.position.distance_to(enemy.target)
 var side := 1.0 if enemy.entity_id % 2 else -1.0
 if enemy.think_clock <= 0:
  enemy.think_clock = [0.32, 0.16, 0.4, 0.27, 0.21, 0.18][enemy.kind]
  enemy.intent = "advance"
  if enemy.kind == 3 and distance < 255:
   enemy.intent = "kite"
  elif enemy.kind == 1 and distance > 155 and enemy.charge_cooldown <= 0:
   enemy.charge_time = 0.52
   enemy.charge_cooldown = 3.2
  elif enemy.kind == 4 and distance < 300:
   enemy.intent = "flank"
  elif enemy.kind == 2 and distance < 270:
   enemy.intent = "guard"
 var direction := toward
 var multiplier := 1.0
 if enemy.intent == "kite":
  direction = -toward * 0.75 + toward.orthogonal() * side * 0.45 if distance < 165 else toward * 0.25 + toward.orthogonal() * side * 0.67
  multiplier = 0.85
 elif enemy.intent == "flank":
  direction = toward * 0.72 + toward.orthogonal() * side * 0.62
 elif enemy.intent == "guard":
  multiplier = 0.88
 if enemy.charge_time > 0:
  multiplier = 1.25
 var separation := Vector2.ZERO
 var count := 0
 for other in neighbors(enemy):
  var offset: Vector2 = enemy.position - other.position
  var d := offset.length()
  if d < 24:
   separation += offset.normalized() * (24 - d) / 24.0 if d > 0.001 else Vector2(side, 1) * 0.5
   count += 1
   if count >= 7:
    break
 return (direction + separation * 0.62).normalized() * multiplier * [1.0, 1.12, 0.91, 0.86, 1.04, 1.0][enemy.kind]
