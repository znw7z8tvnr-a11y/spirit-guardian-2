extends RefCounted
## Filter physical IDs, never items or equipment. Order remains acquisition order.
const MODES=["all","skill","gem","available"]
const TITLES={"all":"全部","skill":"技能","gem":"寶石","available":"可裝配"}
static func ids(model: Node,slot: int,mode: String) -> Array:
 if mode not in MODES or slot<0 or slot>=model.slots.size():return []
 var result: Array=[-1] if mode=="all" else []
 for id in model.items.size():
  var item: Dictionary=model.items[id]
  if mode=="all" or item.kind==mode or (mode=="available" and model.slots[slot]!=id and model.equipment_error(slot,id).is_empty()):result.append(id)
 return result
static func counts(model: Node,slot: int) -> Dictionary:
 var result: Dictionary={}
 for mode in MODES:result[mode]=ids(model,slot,mode).size()-(1 if mode=="all" else 0)
 return result
