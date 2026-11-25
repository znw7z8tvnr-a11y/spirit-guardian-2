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
 model.edges.clear();view.rebuild(model,0)
 check(view.custom_minimum_size.y>720,"disconnected inventory grows scroll area instead of compressing hit areas")
 var unique:=true
 for i in range(10):
  for j in range(i+1,10):
   if view.centers[i].distance_to(view.centers[j])<92:unique=false
 check(unique,"disconnected components and empty slots keep distinct hit areas")
 var scroll:=ScrollContainer.new();scroll.size=Vector2(1180,360);scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;root.add_child(scroll)
 view.reparent(scroll);view.custom_minimum_size.x=1120
 await process_frame;await process_frame
 var slots_before: Array=model.slots.duplicate();var edges_before: Array=model.edges.duplicate(true);var rng_before: int=model.rng.state
 var touch:=InputEventScreenTouch.new();touch.index=0;touch.pressed=true;touch.position=view.nodes[0].get_global_rect().get_center();view._input(touch)
 var drag:=InputEventScreenDrag.new();drag.index=0;drag.position=touch.position+Vector2(0,-5);drag.relative=Vector2(0,-5);view._input(drag)
 check(not view.dragging_tree and scroll.scroll_vertical==0,"small movement preserves node tapping")
 drag.index=1;drag.position=touch.position+Vector2(0,-70);drag.relative=Vector2(0,-70);view._input(drag)
 check(scroll.scroll_vertical==0,"second finger cannot take over tree scrolling")
 drag.index=0;view._input(drag)
 check(view.dragging_tree and scroll.scroll_vertical>0 and hit==[3],"vertical drag scrolls the containing panel without selecting a node")
 touch.pressed=false;view._input(touch)
 check(view.drag_finger== -1 and not view.dragging_tree,"releasing touch ends tree scrolling")
 check(model.slots==slots_before and model.edges==edges_before and model.rng.state==rng_before,"tree scrolling preserves equipment, graph and RNG")
 var overlay:=PanelContainer.new();overlay.size=Vector2(1180,360);root.add_child(overlay)
 # Put both under a Control so normal sibling modal layering applies.
 var host:=Control.new();host.size=Vector2(1280,720);root.add_child(host);scroll.reparent(host);overlay.reparent(host)
 scroll.scroll_vertical=0;await process_frame
 touch.pressed=true;touch.position=view.nodes[0].get_global_rect().get_center();view._input(touch);view._input(drag)
 check(view.drag_finger== -1 and scroll.scroll_vertical==0,"blocking modal overlay prevents dragging the tree behind it")
 overlay.hide();view._input(touch);view.hide()
 check(view.drag_finger== -1,"hiding tree cancels pending gesture")
 view.show();view._input(touch);view.rebuild(model,0)
 check(view.drag_finger== -1,"rebuilding tree clears any stale touch gesture")
 host.queue_free();model.queue_free();await process_frame
 print("TREE_RESULT "+JSON.stringify({"checks":checks,"failures":failures}));quit(1 if failures.size() else 0)
