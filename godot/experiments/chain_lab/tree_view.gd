extends Control
## Touch-friendly view of the actual chain graph. Model owns every rule.
signal slot_selected(index: int)
const Effects=preload("res://experiments/chain_lab/spell_effects.gd")
var model: Node
var selected:=0
var nodes: Array=[]
var centers: Dictionary={}
var cached_visual: Array=[]
var drag_finger:=-1
var drag_origin:=Vector2.ZERO
var dragging_tree:=false
var drag_fraction:=0.0
func rebuild(chain: Node, selection: int) -> void:
 reset_drag()
 var visual:=visual_signature(chain)
 if is_instance_valid(model) and model==chain and cached_visual==visual and nodes.size()==10 and nodes.all(func(button):return is_instance_valid(button) and not button.is_queued_for_deletion() and button.get_parent()==self):
  selected=selection;refresh_selection_styles();queue_redraw();return
 cached_visual=visual
 model=chain;selected=selection
 for child in get_children():remove_child(child);child.queue_free()
 nodes=[];centers={}
 var incoming: Array=[]
 for edge in model.edges:incoming.append(int(edge.to))
 var cursor: Array=[0.0]
 var depth: Dictionary={}
 var lane: Dictionary={}
 for i in range(10):
  if not model.item_at(i).is_empty() and not incoming.has(i):place_subtree(i,0,cursor,depth,lane)
 var max_depth:=1
 for d in depth.values():max_depth=maxi(max_depth,int(d))
 var loose:=0
 var lane_height:=128.0
 var empty_y:=maxf(410,72+float(cursor[0])*lane_height)
 custom_minimum_size.y=empty_y+60
 for i in range(10):
  if depth.has(i):centers[i]=Vector2(74+int(depth[i])*minf(142,940.0/max_depth),72+float(lane[i])*lane_height)
  else:
   centers[i]=Vector2(74+loose*112,empty_y);loose+=1
 for i in range(10):
  var item: Dictionary=model.item_at(i)
  var b:=Button.new();b.position=centers[i]-Vector2(46,46);b.size=Vector2(92,92)
  var style:=StyleBoxFlat.new();style.bg_color=Color("182c48") if not item.is_empty() else Color("111a2b")
  style.border_color=Color("ffe9a2") if i==selected else Color("5c94b7")
  style.set_border_width_all(4 if i==selected else 2);style.set_corner_radius_all(44 if item.is_empty() or item.kind=="skill" else 12)
  b.add_theme_stylebox_override("normal",style);b.add_theme_stylebox_override("hover",style);b.add_theme_stylebox_override("pressed",style)
  b.tooltip_text="第 %d 格" % (i+1);add_child(b);nodes.append(b)
  if not item.is_empty():
   var art:=TextureRect.new();art.mouse_filter=Control.MOUSE_FILTER_IGNORE;art.position=Vector2(16,10);art.size=Vector2(60,60)
   art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
   art.texture=preload("res://experiments/chain_lab/gem_rules.gd").texture(str(item.key)) if item.kind=="gem" else Effects.texture(str(item.key))
   b.add_child(art)
   if item.kind=="gem":art.modulate=preload("res://experiments/chain_lab/gem_rules.gd").tint(str(item.key))
  var caption:=Label.new();caption.mouse_filter=Control.MOUSE_FILTER_IGNORE;caption.text="%02d · %s" % [i+1,"—" if item.is_empty() else "L%d" % int(item.level)]
  caption.add_theme_font_size_override("font_size",18);caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;caption.position=Vector2(0,66);caption.size=Vector2(92,24);b.add_child(caption)
  b.pressed.connect(func():slot_selected.emit(i))
 queue_redraw()
func visual_signature(chain: Node) -> Array:
 var equipped: Array=[]
 for i in range(10):
  var item: Dictionary=chain.item_at(i)
  equipped.append([item.get("id",-1),item.get("kind",""),item.get("key",""),int(item.get("level",0))])
 return [chain.slots.duplicate(),chain.edges.duplicate(true),equipped]
func refresh_selection_styles() -> void:
 for i in nodes.size():
  var style: StyleBoxFlat=nodes[i].get_theme_stylebox("normal")
  var width:=4 if i==selected else 2
  var color:=Color("ffe9a2") if i==selected else Color("5c94b7")
  if style.border_width_left!=width or style.border_color!=color:
   style.border_color=color;style.set_border_width_all(width);nodes[i].queue_redraw()
func place_subtree(index: int, level: int, cursor: Array, depth: Dictionary, lane: Dictionary) -> void:
 depth[index]=level
 var children: Array=[]
 for edge in model.edges:
  if int(edge.from)==index:children.append(int(edge.to))
 if children.is_empty():
  lane[index]=cursor[0];cursor[0]+=1.0
 else:
  for child in children:place_subtree(child,level+1,cursor,depth,lane)
  lane[index]=(float(lane[children.front()])+float(lane[children.back()]))/2.0
func _draw() -> void:
 if not is_instance_valid(model):return
 for edge in model.edges:
  var a: Vector2=centers[int(edge.from)];var b: Vector2=centers[int(edge.to)]
  var direction: Vector2=(b-a).normalized();var start: Vector2=a+direction*48;var end: Vector2=b-direction*50
  draw_line(start,end,Color("193f49"),12,true);draw_line(start,end,Color("69e8c3"),4,true)
  draw_colored_polygon(PackedVector2Array([end,end-direction*16+direction.orthogonal()*7,end-direction*16-direction.orthogonal()*7]),Color("a7ffe2"))

func _ready() -> void:
 visibility_changed.connect(func():
  if not is_visible_in_tree():reset_drag()
 )
func reset_drag() -> void:
 drag_finger=-1;dragging_tree=false;drag_fraction=0.0
func scroll_owner() -> ScrollContainer:
 var ancestor:=get_parent()
 while ancestor!=null:
  if ancestor is ScrollContainer:return ancestor
  ancestor=ancestor.get_parent()
 return null
func touch_area_contains(point: Vector2,scroll: ScrollContainer) -> bool:
 if not get_global_rect().has_point(point) or not scroll.get_global_rect().has_point(point):return false
 # A later blocking sibling on any ancestor branch can cover this view.
 var branch: Node=self
 while branch.get_parent() is Control:
  for sibling in branch.get_parent().get_children().slice(branch.get_index()+1):
   if sibling is Control and sibling.is_visible_in_tree() and sibling.mouse_filter==Control.MOUSE_FILTER_STOP and sibling.get_global_rect().has_point(point):return false
  branch=branch.get_parent()
 return true
func _input(event: InputEvent) -> void:
 if not is_visible_in_tree():return
 var scroll:=scroll_owner()
 if scroll==null:return
 if event is InputEventScreenTouch:
  if event.pressed:
   if drag_finger<0 and touch_area_contains(event.position,scroll):
    drag_finger=event.index;drag_origin=event.position;dragging_tree=false;drag_fraction=0.0
  elif event.index==drag_finger:
   if dragging_tree:get_viewport().set_input_as_handled()
   reset_drag()
 elif event is InputEventScreenDrag and event.index==drag_finger:
  if dragging_tree or absf(event.position.y-drag_origin.y)>12.0:
   if not dragging_tree:
    dragging_tree=true
    for button in nodes:button.notification(Control.NOTIFICATION_SCROLL_BEGIN)
   drag_fraction-=event.relative.y
   var step:=int(drag_fraction)
   drag_fraction-=step
   var before: int=scroll.scroll_vertical
   scroll.scroll_vertical+=step
   if scroll.scroll_vertical-before!=step:drag_fraction=0.0
   get_viewport().set_input_as_handled()

func _notification(what: int) -> void:
 if what==NOTIFICATION_WM_WINDOW_FOCUS_OUT or what==NOTIFICATION_APPLICATION_FOCUS_OUT or what==NOTIFICATION_APPLICATION_PAUSED:
  reset_drag()
  for button in nodes:
   if is_instance_valid(button):button.notification(Control.NOTIFICATION_SCROLL_BEGIN)
