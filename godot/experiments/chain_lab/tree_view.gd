extends Control
## Touch-friendly view of the actual chain graph. Model owns every rule.
signal slot_selected(index: int)
const Effects=preload("res://experiments/chain_lab/spell_effects.gd")
var model: Node
var selected:=0
var nodes: Array=[]
var centers: Dictionary={}
func rebuild(chain: Node, selection: int) -> void:
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
   art.texture=load("res://experiments/chain_lab/assets/relay_gem.svg") if item.kind=="gem" else Effects.texture(str(item.key))
   b.add_child(art)
  var caption:=Label.new();caption.mouse_filter=Control.MOUSE_FILTER_IGNORE;caption.text="%02d · %s" % [i+1,"—" if item.is_empty() else "L%d" % int(item.level)]
  caption.add_theme_font_size_override("font_size",18);caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;caption.position=Vector2(0,66);caption.size=Vector2(92,24);b.add_child(caption)
  b.pressed.connect(func():slot_selected.emit(i))
 queue_redraw()
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
