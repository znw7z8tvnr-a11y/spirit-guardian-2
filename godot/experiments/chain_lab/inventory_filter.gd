extends RefCounted
## Filter physical IDs, never items or equipment. Order remains acquisition order.
const MODES=["all","skill","gem","available"]
const TITLES={"all":"全部","skill":"技能","gem":"寶石","available":"可裝配"}
static func ids(model: Node,slot: int,mode: String) -> Array:
 if not is_instance_valid(model) or mode not in MODES or slot<0 or slot>=model.slots.size():return []
 var result: Array=[-1] if mode=="all" else []
 for id in model.items.size():
  var item: Dictionary=model.items[id]
  if mode=="all" or item.kind==mode or (mode=="available" and model.slots[slot]!=id and model.equipment_error(slot,id).is_empty()):result.append(id)
 return result
static func snapshot(model: Node,slot: int,mode: String="") -> Dictionary:
 var totals: Dictionary={"all":0,"skill":0,"gem":0,"available":0}
 var visible_ids: Array=[]
 if not is_instance_valid(model) or slot<0 or slot>=model.slots.size() or (not mode.is_empty() and mode not in MODES):return {"ids":visible_ids,"counts":totals}
 totals.all=model.items.size()
 if mode=="all":visible_ids.append(-1)
 for id in model.items.size():
  var item: Dictionary=model.items[id]
  if item.kind in ["skill","gem"]:totals[item.kind]+=1
  var available: bool=model.slots[slot]!=id and model.equipment_error(slot,id).is_empty()
  if available:totals.available+=1
  if mode=="all" or item.kind==mode or (mode=="available" and available):visible_ids.append(id)
 return {"ids":visible_ids,"counts":totals}
static func counts(model: Node,slot: int) -> Dictionary:
 return snapshot(model,slot).counts
