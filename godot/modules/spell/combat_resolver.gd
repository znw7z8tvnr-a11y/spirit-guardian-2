extends Node
signal hit_resolved(enemy: Node2D, result: Dictionary, context: Dictionary)
var serial := 0
var rng := RandomNumberGenerator.new()
func _ready() -> void:
 rng.seed=1201
func resolve(enemy: Node2D, amount: float, element: String, context: Dictionary = {}) -> Dictionary:
 if not is_instance_valid(enemy) or enemy.dead or not is_finite(amount) or amount <= 0:
  return {}
 serial += 1
 var ctx := context.duplicate(true)
 ctx["event_id"] = serial
 if not ctx.get("status_tick",false) and not ctx.has("critical"):
  ctx["critical"]=rng.randf()<0.12
 if ctx.get("critical",false):amount*=1.85
 var result: Dictionary = enemy.apply_hit(minf(amount, 1000000), element, ctx)
 if not result.is_empty():
  hit_resolved.emit(enemy, result, ctx)
 return result
