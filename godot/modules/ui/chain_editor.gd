extends PanelContainer
signal closed
const Catalog = preload("res://modules/spell/catalog.gd")
var model: Node
var graph: GraphEdit
var skill: OptionButton
var gem: OptionButton
var quality: SpinBox
var status: Label
var json_text: TextEdit
var chosen := -1
var history: Array=[]
var future: Array=[]
var action_buttons: Dictionary={}
func setup(chain: Node) -> void:
 model=chain
 var backdrop:=StyleBoxFlat.new()
 backdrop.bg_color=Color("101727")
 backdrop.border_color=Color("637a94")
 backdrop.set_border_width_all(1)
 backdrop.set_content_margin_all(12)
 add_theme_stylebox_override("panel",backdrop)
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 offset_left=16;offset_top=16;offset_right=-16;offset_bottom=-16
 var box:=VBoxContainer.new()
 add_child(box)
 var title:=Label.new()
 title.text="FREE CHAIN GRAPH • drag sockets to connect • cycles rejected"
 box.add_child(title)
 var bar:=HBoxContainer.new()
 box.add_child(bar)
 skill=OptionButton.new()
 for key in Catalog.PLAYABLE:skill.add_item(key)
 bar.add_child(skill)
 gem=OptionButton.new()
 for key in Catalog.data.GEM:gem.add_item(key)
 bar.add_child(gem)
 quality=SpinBox.new();quality.min_value=1;quality.max_value=3;quality.value=3
 bar.add_child(quality)
 button("Add",bar,func():remember();model.add_node(skill.get_item_text(skill.selected),gem.get_item_text(gem.selected),int(quality.value));rebuild())
 button("Remove",bar,func():remember();model.remove_node(chosen);rebuild())
 button("Done",bar,func():closed.emit())
 var tools:=HBoxContainer.new();box.add_child(tools)
 button("Demo",tools,func():remember();model.demo();rebuild())
 button("Undo",tools,undo)
 button("Redo",tools,redo)
 button("Export JSON",tools,func():json_text.text=JSON.stringify(model.build(),"  "))
 button("Import JSON",tools,func():
  var parsed: Variant=JSON.parse_string(json_text.text)
  var before: Dictionary=model.build()
  if model.restore(parsed):
   history.append(before);future.clear();rebuild();status.text="Imported build"
  else:status.text="Import rejected: invalid, unsupported spell, or cyclic graph"
 )
 graph=GraphEdit.new()
 graph.custom_minimum_size=Vector2(400,260)
 graph.size_flags_vertical=Control.SIZE_EXPAND_FILL
 box.add_child(graph)
 graph.connection_request.connect(func(from:StringName,_port:int,to:StringName,_to_port:int):remember();model.connect_nodes(int(String(from)),int(String(to)));rebuild())
 graph.disconnection_request.connect(func(from:StringName,_port:int,to:StringName,_to_port:int):remember();model.disconnect_nodes(int(String(from)),int(String(to)));rebuild())
 graph.node_selected.connect(func(node:Node):chosen=int(String(node.name)))
 graph.begin_node_move.connect(remember)
 graph.end_node_move.connect(func():
  for child in graph.get_children():
   if child is GraphNode:
    var data: Dictionary=model.find(int(String(child.name)))
    if not data.is_empty():data.x=child.position_offset.x;data.y=child.position_offset.y
 )
 status=Label.new();box.add_child(status)
 json_text=TextEdit.new();json_text.custom_minimum_size=Vector2(0,72);json_text.placeholder_text="Build JSON import/export (Godot schema 1; original V9 tree format is kept as reference)";box.add_child(json_text)
 rebuild()
func button(text:String,parent:Node,action:Callable) -> void:
 var b:=Button.new();b.text=text;b.custom_minimum_size=Vector2(88,48);parent.add_child(b);b.pressed.connect(action);action_buttons[text]=b
func remember() -> void:
 history.append(model.build());future.clear()
 if history.size()>40:history.pop_front()
func undo() -> void:
 if history.is_empty():return
 future.append(model.build());model.restore(history.pop_back());rebuild()
func redo() -> void:
 if future.is_empty():return
 history.append(model.build());model.restore(future.pop_back());rebuild()
func rebuild() -> void:
 graph.clear_connections()
 for child in graph.get_children():
  if child is GraphNode:
   graph.remove_child(child);child.queue_free()
 for data in model.nodes:
  var node:=GraphNode.new()
  node.name=str(int(data.id));node.title=str(data.key)+" / "+str(data.gem)+" Q"+str(data.quality)
  node.position_offset=Vector2(float(data.x),float(data.y))
  var node_style:=StyleBoxFlat.new()
  node_style.bg_color=Color("202e44")
  node_style.border_color=Color("6687a2")
  node_style.set_border_width_all(1)
  node.add_theme_stylebox_override("panel",node_style)
  var label:=Label.new();label.text=" IN        >        OUT ";label.custom_minimum_size=Vector2(180,48);node.add_child(label)
  node.set_slot(0,true,0,Color("89e6ff"),true,0,Color("ffd484"))
  graph.add_child(node)
 for edge in model.edges:graph.connect_node(str(int(edge.from)),0,str(int(edge.to)),0)
 status.text="%d nodes / %d links • Q1–3 gems • 16 depth / 240 events safety budget" % [model.nodes.size(),model.edges.size()]
