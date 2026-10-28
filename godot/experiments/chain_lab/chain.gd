extends Node
signal changed
signal cast_requested(slot: int, item: Dictionary, target: Node2D, run: Dictionary)
signal pulse(slot: int, message: String)
signal resonance_requested(recipe: String, target: Node2D)
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
 pending.clear();active.clear()
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
func start(target: Node2D) -> bool:
 if not active.is_empty() or not is_instance_valid(target) or target.dead:return false
 serial+=1
 active={"id":serial,"events":0,"elements":[],"checked":false,"inflight":1}
 cast_requested.emit(0,item_at(0),target,active)
 return true
func current(run: Dictionary) -> bool:
 return not active.is_empty() and active.id==run.id
func complete_skill(slot: int, target: Node2D, result: Dictionary, run: Dictionary) -> void:
 if not current(run):return
 run.inflight-=1
 var item:=item_at(slot)
 if item.is_empty():finish_if_idle();return
 casts+=1
 var element:=Catalog.element(str(item.key))
 if element not in run.elements:run.elements.append(element)
 run["last_at"]=result.get("position",Vector2.ZERO)
 pulse.emit(slot,"%s命中" % str(item.key))
 for recipe in Catalog.data.FINISHERS:
  var matches:=true
  for needed in str(recipe).split("+"):
   if needed not in run.elements:matches=false
  if matches and not run.checked:
   run.checked=true
   if clock>=cooldown_until:
    rolls+=1
    if rng.randf()<resonance_chance:
     cooldown_until=clock+resonance_cooldown;resonances+=1
     if recipe not in discovered:discovered.append(recipe)
     resonance_requested.emit(str(recipe),target)
   break
 for edge in outgoing(slot):schedule(int(edge.to),target,result,run)
 finish_if_idle()
func schedule(slot: int, target: Node2D, result: Dictionary, run: Dictionary) -> void:
 if int(run.events)>=MAX_EVENTS:return
 run.events+=1
 var at: Vector2=result.get("position",target.position if is_instance_valid(target) else Vector2.ZERO)
 pending.append({"slot":slot,"target":weakref(target) if is_instance_valid(target) else null,"at":at,"result":result,"run":run,"due":clock+hop_delay})
func advance(delta: float) -> void:
 clock+=delta
 var ready:=pending.filter(func(e):return float(e.due)<=clock)
 pending=pending.filter(func(e):return float(e.due)>clock)
 for event in ready:
  var run: Dictionary=event.run
  if not current(run):continue
  var target: Node2D=event.target.get_ref() if event.target!=null else null
  if not is_instance_valid(target) or target.dead:
   target=host.target_near(event.at,retarget_radius) if is_instance_valid(host) else null
   if target!=null:retargets+=1;last_message="目標已倒下，剩餘連鎖轉移至附近怪物。"
  if target==null:continue
  var item:=item_at(int(event.slot))
  if item.is_empty():continue
  if item.kind=="gem":
   pulse.emit(int(event.slot),"寶石判定")
   if rng.randf()<[0.0,0.85,0.93,1.0][int(item.level)]:
    for edge in outgoing(int(event.slot)):schedule(int(edge.to),target,event.result,run)
   else:last_message="寶石這次未觸發，該支線結束。"
  else:
   run.inflight+=1;cast_requested.emit(int(event.slot),item,target,run)
 finish_if_idle()
func finish_if_idle() -> void:
 if not active.is_empty() and int(active.inflight)==0 and pending.is_empty():active={}
