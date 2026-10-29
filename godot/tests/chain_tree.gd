extends SceneTree
var checks: Array=[]
var failures: Array=[]
func check(ok: bool,message: String) -> void:
 if ok:checks.append(message)
 else:failures.append(message)
func _initialize() -> void:call_deferred("run")
func run() -> void:
 var model=load("res://experiments/chain_lab/chain.gd").new();root.add_child(model)
 var view=load("res://experiments/chain_lab/tree_view.gd").new();root.add_child(view)
 view.rebuild(model,0)
 check(view.nodes.size()==10,"empty slots remain selectable before obtaining items")
 model.load_kit();view.rebuild(model,3)
 check(view.nodes.size()==10 and view.selected==3,"kit preserves ten-slot capacity and selection")
 for edge in model.edges:
  check(view.centers[int(edge.to)].x>view.centers[int(edge.from)].x,"edge advances in displayed cast direction")
 check(view.centers[2].y!=view.centers[3].y,"gem forks occupy visibly separate lanes")
 var hit: Array=[];view.slot_selected.connect(func(index: int):hit.append(index))
 view.nodes[3].pressed.emit();check(hit==[3],"touch node emits the exact physical slot")
 var inventory: Array=model.slots.duplicate();view.rebuild(model,7)
 check(model.slots==inventory,"selection redraw does not change equipment")
 for i in range(10):
  for j in range(i+1,10):check(view.centers[i].distance_to(view.centers[j])>=92,"node hit areas do not overlap")
 view.queue_free();model.queue_free();await process_frame
 print("TREE_RESULT "+JSON.stringify({"checks":checks,"failures":failures}));quit(1 if failures.size() else 0)
