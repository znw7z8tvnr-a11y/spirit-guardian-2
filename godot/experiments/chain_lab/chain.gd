extends Node
signal changed
signal cast_requested(slot: int, item: Dictionary, target: Node2D, run: Dictionary, context: Dictionary)
signal pulse(slot: int, message: String)
signal resonance_requested(recipe: String, at: Vector2, run_id: int)
const Catalog=preload("res://modules/spell/catalog.gd")
const CAPACITY:=10
const MAX_EVENTS:=24
var items: Array=[]
var slots: Array=[]
var edges: Array=[]
var pending: Array=[]
var rng:=RandomNumberGenerator.new()
var host: Node
var clock:=0.0
var cooldown_until:=0.0
var hop_delay:=0.32
var resonance_chance:=0.30
var resonance_cooldown:=8.0
var retarget_radius:=480.0
var discovered: Array=[]
var active: Dictionary={}
var serial:=0
var casts:=0
var hits:=0
var misses:=0
var jumps:=0
var empty_casts:=0
var trace: Array=[]
var retargets:=0
var rolls:=0
var resonances:=0
var kit_loaded:=false
var last_message:="開局只有奧彈；可載入試驗配置測試連鎖。"
func _init() -> void:
 rng.randomize()
 slots.resize(CAPACITY);slots.fill(-1)
 items=[{"id":0,"kind":"skill","key":"arcane","level":1}]
 slots[0]=0
func item_at(slot: int) -> Dictionary:
 return items[int(slots[slot])] if slot>=0 and slot<CAPACITY and int(slots[slot])>=0 else {}
func equip(slot: int, id: int) -> bool:
 if slot<0 or slot>=CAPACITY or id< -1 or id>=items.size():return false
 if slot==0 and (id<0 or items[id].kind!="skill"):return false
 if id>=0 and slots.has(id) and slots[slot]!=id:return false
 var old: int=slots[slot]
 slots[slot]=id
 for e in edges:
  if not legal_edge(int(e.from),int(e.to),false):slots[slot]=old;return false
 reset_runtime();changed.emit();return true
func outgoing(id: int) -> Array:
 return edges.filter(func(e):return int(e.from)==id)
func legal_edge(from: int, to: int, check_limit:=true) -> bool:
 var a:=item_at(from);var b:=item_at(to)
 if a.is_empty() or b.is_empty() or from==to or to==0 or a.kind==b.kind:return false
 var maximum:=2 if a.kind=="gem" and int(a.level)==3 else 1
 if check_limit and (outgoing(from).size()>=maximum or edges.any(func(e):return int(e.to)==to)):return false
 if not check_limit and outgoing(from).size()>maximum:return false
 return true
func connect_slots(from: int, to: int) -> bool:
 if not legal_edge(from,to):return false
 var todo: Array=[to];var seen: Array=[]
 while not todo.is_empty():
  var id: int=todo.pop_back()
  if id==from:return false
  if id in seen:continue
  seen.append(id)
  for e in outgoing(id):todo.append(int(e.to))
 edges.append({"from":from,"to":to});reset_runtime();changed.emit();return true
func disconnect_slots(from: int, to: int) -> void:
 edges=edges.filter(func(e):return not (int(e.from)==from and int(e.to)==to))
 reset_runtime();changed.emit()
func reset_runtime() -> void:
 pending.clear();active={}
func load_kit() -> void:
 if not kit_loaded:
  for spec in [["gem","relay",3],["skill","fire",1],["skill","ice",2],["gem","relay",1],["skill","lightning",1],["gem","relay",2],["skill","arcane",2],["skill","fire",3],["gem","relay",1]]:
   items.append({"id":items.size(),"kind":spec[0],"key":spec[1],"level":spec[2]})
  kit_loaded=true
 slots=[0,1,2,3,4,5,6,7,-1,-1]
 edges=[{"from":0,"to":1},{"from":1,"to":2},{"from":1,"to":3},{"from":3,"to":4},{"from":4,"to":5},{"from":2,"to":6},{"from":6,"to":7}]
 reset_runtime();last_message="已載入測試用物品；不是正式掉落。";changed.emit()
func random_arrange() -> void:
 if not kit_loaded:return
 var skills:=items.filter(func(i):return i.kind=="skill" and int(i.id)!=0)
 var gems:=items.filter(func(i):return i.kind=="gem")
 # Use this instance RNG; no global state or duplicate inventory items.
 for list in [skills,gems]:
  for i in range(list.size()-1,0,-1):
   var j:=rng.randi_range(0,i);var value: Variant=list[i];list[i]=list[j];list[j]=value
 slots.fill(-1);slots[0]=0;edges=[]
 for i in range(1,CAPACITY):
  var choices: Array=gems if i%2==1 else skills
  if choices.is_empty():break
  var item: Dictionary=choices.pop_back();slots[i]=int(item.id)
  edges.append({"from":i-1,"to":i})
 reset_runtime();changed.emit()
func target_id(target: Node2D) -> int:
 return target.get_instance_id() if is_instance_valid(target) else 0
func alive(target: Node2D) -> bool:
 return is_instance_valid(target) and not target.dead
func start(target: Node2D) -> bool:
 # No target: finish an existing cycle, but never create a new empty cycle.
 if not active.is_empty() or not alive(target):return false
 serial+=1
 active={"id":serial,"events":0,"elements":[],"checked":false,"inflight":0,"visited":[]}
 emit_skill(0,target,active,{"origin":host.CENTER+Vector2(0,-65) if is_instance_valid(host) else target.position,"aim":target.position,"previous_id":0})
 return true
func current(run: Dictionary) -> bool:
 return not active.is_empty() and active.get("id",-1)==run.get("id",-2)
func add_trace(event: Dictionary) -> void:
 trace.append(event)
 if trace.size()>80:trace.pop_front()
func choose_target(at: Vector2, run: Dictionary) -> Node2D:
 if not is_instance_valid(host):return null
 var candidates: Array=host.enemies.get_children().filter(func(e):return alive(e) and e.position.distance_squared_to(at)<=retarget_radius*retarget_radius)
 candidates.sort_custom(func(a,b):
  var da: float=a.position.distance_squared_to(at);var db: float=b.position.distance_squared_to(at)
  return target_id(a)<target_id(b) if is_equal_approx(da,db) else da<db
 )
 for enemy in candidates:
  if target_id(enemy) not in run.visited:return enemy
 return candidates[0] if not candidates.is_empty() else null
func emit_skill(slot: int, target: Node2D, run: Dictionary, context: Dictionary) -> void:
 if not current(run):return
 var item:=item_at(slot)
 if item.is_empty():return
 var id:=target_id(target)
 if id>0:
  if id not in run.visited:run.visited.append(id)
  if int(context.get("previous_id",0))>0 and id!=int(context.previous_id):jumps+=1
 else:empty_casts+=1
 context["aim"]=target.position if alive(target) else context.aim
 context["target_id"]=id
 context["slot"]=slot
 context["run_id"]=run.id
 run.inflight+=1;casts+=1
 var element:=Catalog.element(str(item.key))
 if element not in run.elements:run.elements.append(element)
 run["last_at"]=context.aim
 add_trace({"kind":"cast","run":run.id,"slot":slot,"key":item.key,"target":id,"origin":[context.origin.x,context.origin.y],"at":[context.aim.x,context.aim.y],"empty":id==0})
 pulse.emit(slot,"施放")
 # Create the actual spell first. Its flight need not hit to provide an element.
 cast_requested.emit(slot,item.duplicate(true),target,run,context)
 evaluate_resonance(run,context.aim)
func evaluate_resonance(run: Dictionary, at: Vector2) -> void:
 if not current(run) or run.checked:return
 for recipe in Catalog.data.FINISHERS:
  var matches:=true
  for needed in str(recipe).split("+"):
   if needed not in run.elements:matches=false
  if not matches:continue
  run.checked=true
  if clock>=cooldown_until:
   rolls+=1
   if rng.randf()<resonance_chance:
    cooldown_until=clock+resonance_cooldown;resonances+=1
    if recipe not in discovered:discovered.append(recipe)
    resonance_requested.emit(str(recipe),at,int(run.id))
  break
func complete_skill(slot: int, target: Node2D, result: Dictionary, run: Dictionary, context: Dictionary={}) -> void:
 if not current(run):return
 # Impact callbacks are idempotent; a multi-victim spell advances only once.
 if context.get("completed",false):return
 context["completed"]=true
 run.inflight-=1
 var item:=item_at(slot)
 if item.is_empty():finish_if_idle();return
 var hit: bool=bool(result.get("hit",not result.is_empty()))
 var outcome:=result.duplicate(true)
 outcome["hit"]=hit
 outcome["killed"]=bool(outcome.get("killed",false)) if hit else false
 outcome["critical"]=bool(outcome.get("critical",false)) if hit else false
 outcome["position"]=outcome.get("position",context.get("aim",Vector2.ZERO))
 outcome["previous_id"]=context.get("target_id",target_id(target))
 if hit:hits+=1
 else:misses+=1
 add_trace({"kind":"hit" if hit else "miss","run":run.id,"slot":slot,"target":outcome.previous_id})
 for edge in outgoing(slot):schedule(int(edge.to),target,outcome,run)
 finish_if_idle()
func schedule(slot: int, target: Node2D, result: Dictionary, run: Dictionary) -> void:
 if int(run.events)>=MAX_EVENTS:return
 run.events+=1
 var at: Vector2=result.get("position",target.position if is_instance_valid(target) else Vector2.ZERO)
 pending.append({"slot":slot,"target":weakref(target) if is_instance_valid(target) else null,"at":at,"result":result.duplicate(true),"run":run,"due":clock+hop_delay})
func gem_succeeds(item: Dictionary, source: Dictionary) -> bool:
 var hit: bool=source.get("hit",false)
 match str(item.key):
  "hit":
   if not hit:return false
  "kill":
   if not hit or not source.get("killed",false):return false
  "crit":
   if not hit or not source.get("critical",false):return false
  "burn":
   if not hit or source.get("element","")!="fire":return false
  "freeze":
   if not hit or source.get("element","")!="ice":return false
 # Existing lab relay probabilities remain tuning values, not a final economy.
 return rng.randf()<[0.0,0.85,0.93,1.0][int(item.level)]
func advance(delta: float) -> void:
 clock+=delta
 var ready:=pending.filter(func(e):return float(e.due)<=clock)
 pending=pending.filter(func(e):return float(e.due)>clock)
 for event in ready:
  var run: Dictionary=event.run
  if not current(run):continue
  var previous: Node2D=event.target.get_ref() if event.target!=null else null
  var item:=item_at(int(event.slot))
  if item.is_empty():continue
  if item.kind=="gem":
   pulse.emit(int(event.slot),"寶石判定")
   var success:=gem_succeeds(item,event.result)
   add_trace({"kind":"gem","run":run.id,"slot":event.slot,"success":success})
   if success:
    for edge in outgoing(int(event.slot)):schedule(int(edge.to),previous,event.result,run)
   else:last_message="寶石條件未滿足或機率未觸發，該支線結束。"
  else:
   var target:=choose_target(event.at,run)
   if target!=null and not alive(previous):retargets+=1
   var context: Dictionary={"origin":event.at,"aim":event.at,"previous_id":event.result.get("previous_id",target_id(previous))}
   emit_skill(int(event.slot),target,run,context)
 finish_if_idle()
func finish_if_idle() -> void:
 if not active.is_empty() and int(active.inflight)==0 and pending.is_empty():active={}
