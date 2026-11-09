extends Node2D
## Explicit simulation step, called only by the active combat loop.
const Actor=preload("res://experiments/chain_lab/guardian_actor.gd")
const SENSE=400.0
const REACH=65.0
const SPEED=88.0
const PERIOD=0.55
const LIFE=8.0
var targets: Node2D
var resolver: Node
var guards: Array[Node2D]=[]
var spawns:=0
var hits:=0
var kills:=0
func purge() -> void:
 guards=guards.filter(func(g):return is_instance_valid(g) and not g.is_queued_for_deletion() and g.remaining>0)
func summon_at(at: Vector2, level: int, boost: float) -> Node2D:
 purge()
 if not at.is_finite() or not is_finite(boost) or boost<=0:return null
 var tier:=clampi(level,1,3)
 if guards.size()>=tier+1:return null
 var guard:=Actor.new();guard.position=at+Vector2(-24,16);guard.remaining=LIFE;guard.power=9.0*(1+0.55*(tier-1))*boost;add_child(guard);guards.append(guard);spawns+=1;return guard
func choose(at: Vector2) -> Node2D:
 if not is_instance_valid(targets):return null
 var best: Node2D=null;var distance:=SENSE*SENSE
 for enemy in targets.get_children():
  if not is_instance_valid(enemy) or enemy.dead or enemy.is_queued_for_deletion():continue
  var d: float=at.distance_squared_to(enemy.position)
  if d<=distance:
   if best==null or d<distance or enemy.get_instance_id()<best.get_instance_id():best=enemy;distance=d
 return best
func advance(delta: float) -> void:
 if not is_finite(delta) or delta<=0:return
 purge()
 for guard in guards:
  guard.remaining=maxf(0.0,guard.remaining-delta);guard.age+=delta;guard.cooldown=maxf(0.0,guard.cooldown-delta)
  if guard.remaining<=0:guard.queue_free();continue
  var enemy:=choose(guard.position);guard.target_id=0;guard.intent="待命"
  if enemy!=null:
   guard.target_id=enemy.get_instance_id()
   var distance: float=guard.position.distance_to(enemy.position)
   if distance>REACH:
    guard.intent="追擊";guard.position=guard.position.move_toward(enemy.position,minf(SPEED*delta,distance-REACH))
   elif guard.cooldown<=0 and is_instance_valid(resolver):
    var result: Dictionary=resolver.resolve(enemy,guard.power,"lightning",{"critical":false,"guardian_hit":true,"spell_key":"guardian_strike"})
    if not result.is_empty():
     guard.intent="攻擊";guard.strikes+=1;guard.flash=0.14+delta;guard.strike_point=enemy.position;guard.cooldown=PERIOD;hits+=1
     if result.get("killed",false):kills+=1
  guard.present(delta)
 purge()
func snapshot() -> Array:
 purge();var rows: Array=[]
 for guard in guards:rows.append({"position":[guard.position.x,guard.position.y],"life":guard.remaining,"power":guard.power,"strikes":guard.strikes,"target":guard.target_id,"intent":guard.intent,"cooldown":guard.cooldown})
 return rows
