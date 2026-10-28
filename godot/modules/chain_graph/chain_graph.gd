extends Node
signal cast_requested(key: String, target: Node2D, power: float, context: Dictionary)
signal changed
signal reaction_activated(at: Vector2)
const Catalog = preload("res://modules/spell/catalog.gd")
const Resonance = preload("res://modules/resonance/resonance.gd")
const ATTACK_GEMS := ["blast","bolt","venom","frostatk","critical","piercing","range","multi"]
const MAX_DEPTH := 16
const MAX_EVENTS := 240
const MAX_PENDING := 400
const MAX_PER_TICK := 24
var nodes: Array = []
var edges: Array = []
var pending: Array = []
var clock := 0.0
var cooldowns := {}
var rng := RandomNumberGenerator.new()
var casts := 0
var skipped := 0
var fusions := 0
var finishers := 0
var uid := 1
var host: Node
var reactions := Resonance.new()
func _init() -> void:
 rng.seed = 9001
 demo()
func demo() -> void:
 nodes = [{"id":1,"key":"fire","gem":"split","quality":3,"x":40.0,"y":40.0},{"id":2,"key":"ice","gem":"split","quality":3,"x":280.0,"y":40.0},{"id":3,"key":"lightning","gem":"split","quality":3,"x":520.0,"y":40.0},{"id":4,"key":"arcane","gem":"hit","quality":3,"x":760.0,"y":40.0},{"id":5,"key":"meteor","gem":"hit","quality":3,"x":520.0,"y":250.0}]
 edges = [{"from":1,"to":2},{"from":2,"to":3},{"from":3,"to":4},{"from":2,"to":5}]
 uid = 6
 reset_runtime()
 changed.emit()
func reset_runtime() -> void:
 pending.clear()
 cooldowns.clear()
 clock = 0
func find(id: int) -> Dictionary:
 for node in nodes:
  if int(node.id) == id:
   return node
 return {}
func outgoing(id: int) -> Array:
 return edges.filter(func(edge): return int(edge.from) == id)
func add_node(key: String, gem: String, quality: int) -> int:
 if key not in Catalog.PLAYABLE or not Catalog.data.GEM.has(gem) or nodes.size() >= 500:
  return -1
 var id := uid
 uid += 1
 var next_y:=40.0
 for node in nodes:next_y=maxf(next_y,float(node.y)+200)
 nodes.append({"id":id,"key":key,"gem":gem,"quality":clampi(quality,1,3),"x":40.0,"y":next_y})
 changed.emit()
 return id
func remove_node(id: int) -> void:
 nodes = nodes.filter(func(node):return int(node.id) != id)
 edges = edges.filter(func(edge):return int(edge.from) != id and int(edge.to) != id)
 changed.emit()
func connect_nodes(from: int, to: int) -> bool:
 if edges.size()>=2000 or from == to or find(from).is_empty() or find(to).is_empty() or edges.has({"from":from,"to":to}):
  return false
 var todo := [to]
 var seen := {}
 while not todo.is_empty():
  var id: int = todo.pop_back()
  if id == from:
   return false
  if seen.has(id):
   continue
  seen[id] = true
  for edge in outgoing(id):
   todo.append(int(edge.to))
 edges.append({"from":from,"to":to})
 changed.emit()
 return true
func disconnect_nodes(from: int, to: int) -> void:
 edges = edges.filter(func(edge):return not (int(edge.from)==from and int(edge.to)==to))
 changed.emit()
func build() -> Dictionary:
 return {"schema":1,"nodes":nodes.duplicate(true),"edges":edges.duplicate(true)}
func restore(data: Variant) -> bool:
 # Validate transactionally in a detached graph; failed import leaves current graph intact.
 if typeof(data)!=TYPE_DICTIONARY:
  return false
 var schema: Variant=data.get("schema")
 if not (schema is float or schema is int) or schema!=1:
  return false
 if typeof(data.get("nodes")) != TYPE_ARRAY or typeof(data.get("edges")) != TYPE_ARRAY or data.nodes.size() > 500 or data.edges.size() > 2000:
  return false
 var candidate: Node = get_script().new()
 candidate.nodes = []
 candidate.edges = []
 var ids := {}
 for node in data.nodes:
  if typeof(node) != TYPE_DICTIONARY or not (node.get("id") is float or node.get("id") is int) or not is_finite(float(node.id)) or float(node.id) != int(node.id) or int(node.id) < 1 or ids.has(int(node.id)) or node.get("key") not in Catalog.PLAYABLE or not Catalog.data.GEM.has(node.get("gem", "")):
   candidate.free()
   return false
  var q: Variant = node.get("quality", 1)
  if not (q is float or q is int) or not is_finite(float(q)) or q < 1 or q > 3 or float(q)!=int(q):
   candidate.free()
   return false
  for axis in ["x","y"]:
   var value: Variant = node.get(axis, 0)
   if not (value is float or value is int) or not is_finite(float(value)) or absf(float(value)) > 100000:
    candidate.free()
    return false
  ids[int(node.id)] = true
  candidate.nodes.append({"id":int(node.id),"key":node.key,"gem":node.gem,"quality":int(q),"x":float(node.get("x",0)),"y":float(node.get("y",0))})
 for edge in data.edges:
  if typeof(edge)!=TYPE_DICTIONARY or not (edge.get("from") is float or edge.get("from") is int) or not (edge.get("to") is float or edge.get("to") is int) or not is_finite(float(edge.from)) or not is_finite(float(edge.to)) or float(edge.from)!=int(edge.from) or float(edge.to)!=int(edge.to) or not candidate.connect_nodes(int(edge.from),int(edge.to)):
   candidate.free()
   return false
 nodes = candidate.nodes.duplicate(true)
 edges = candidate.edges.duplicate(true)
 uid = 1
 for id in ids:
  uid = maxi(uid, int(id)+1)
 candidate.free()
 reset_runtime()
 changed.emit()
 return true
func gem_boost(node: Dictionary) -> float:
 var q := int(node.quality)-1
 var bonuses := {"blast":[0.15,0.30,0.5],"bolt":[0.12,0.25,0.45],"venom":[0.1,0.22,0.4],"frostatk":[0.1,0.2,0.35],"critical":[0.2,0.4,0.7],"piercing":[0.12,0.25,0.45],"range":[0.1,0.2,0.35],"multi":[0.15,0.3,0.5],"split":[0.1,0.2,0.35],"rapid":[0.1,0.2,0.35]}
 return 1.0 + float(bonuses.get(node.gem,[0,0,0])[q])
func condition(node: Dictionary, target: Node2D, result: Dictionary) -> bool:
 var q := int(node.quality)-1
 match node.gem:
  "hit":return rng.randf() < [0.30,0.45,0.60][q]
  "chance":return rng.randf() < [0.25,0.45,0.65][q]
  "crit":return result.get("critical", false) and rng.randf() < [0.20,0.35,0.50][q]
  "kill":return result.get("killed",false) and rng.randf() < [0.4,0.7,1.0][q]
  "freeze":return (target.slow_time>0 or result.element=="ice") and rng.randf() < [0.4,0.65,0.9][q]
  "burn":return result.element=="fire" and rng.randf() < [0.4,0.65,0.9][q]
  "echo":return rng.randf() < [0.20,0.35,0.50][q]
  "lowhp":return target.hp <= target.max_hp * [0.25,0.40,0.55][q]
  "delay":
   if clock-float(cooldowns.get(node.id,-1000)) < [3,2,1][q]:return false
   cooldowns[node.id]=clock
 return true
func on_primary(enemy: Node2D, result: Dictionary, key: String) -> void:
 for node in nodes:
  if node.key != key or edges.any(func(edge):return int(edge.to)==int(node.id)):
   continue
  var run := {"count":0,"elements":[Catalog.element(key)],"finisher":false}
  schedule_children(node, enemy, result, run, 0, 1.0, Catalog.element(key))
func schedule_children(node: Dictionary, target: Node2D, result: Dictionary, run: Dictionary, depth: int, multiplier: float, previous: String) -> void:
 if not condition(node, target, result):return
 for edge in outgoing(int(node.id)):
  if depth >= MAX_DEPTH or int(run.count)>=MAX_EVENTS or pending.size()>=MAX_PENDING:
   skipped += 1
   continue
  run.count += 1
  pending.append({"node":int(edge.to),"target":weakref(target),"due":clock+0.14+min(depth,6)*0.085,"depth":depth+1,"multiplier":multiplier*(gem_boost(node) if node.gem not in ATTACK_GEMS else 1.0),"previous":previous,"run":run})
func _physics_process(delta: float) -> void:
 clock += delta
 pending.sort_custom(func(a,b):return a.due<b.due)
 var processed := 0
 while not pending.is_empty() and pending[0].due<=clock and processed<MAX_PER_TICK:
  var event: Dictionary = pending.pop_front()
  processed += 1
  var node := find(int(event.node))
  if node.is_empty() or not is_instance_valid(host):continue
  var target: Node2D = event.target.get_ref()
  if not is_instance_valid(target) or target.dead:
   target=host.nearest_enemy()
  if target==null:
   skipped+=1
   continue
  var element := Catalog.element(node.key)
  var run: Dictionary = event.run
  if element not in run.elements:run.elements.append(element)
  var reaction: Dictionary = reactions.evaluate(event.previous, element, run.elements, run.finisher)
  if reaction.fusion!="":fusions+=1
  if reaction.finisher!="":
   run.finisher=true
   finishers+=1
  if reaction.fusion!="" or reaction.finisher!="":reaction_activated.emit(target.position)
  var context := {"chain":true,"graph_event":event,"node":int(node.id),"key":node.key}
  casts+=1
  cast_requested.emit(node.key,target,Catalog.power(node.key)*(1+float(event.depth)*0.28)*float(event.multiplier)*float(reaction.multiplier)*(gem_boost(node) if node.gem in ATTACK_GEMS else 1.0),context)
func on_chain_hit(enemy: Node2D, result: Dictionary, context: Dictionary) -> void:
 # A multi-victim spell advances its graph only once, while every victim takes its damage.
 var event: Dictionary = context.graph_event
 if event.get("advanced",false):return
 event["advanced"]=true
 var node:=find(int(context.node))
 if not node.is_empty():schedule_children(node,enemy,result,event.run,int(event.depth),float(event.multiplier),Catalog.element(node.key))

func root_boost(key: String) -> float:
 var boost:=1.0
 for node in nodes:
  if node.key==key and node.gem in ATTACK_GEMS and not edges.any(func(e):return int(e.to)==int(node.id)):
   boost=maxf(boost,gem_boost(node))
 return boost
