extends PanelContainer
signal closed
const Zh = preload("res://localization/zh_hant.gd")
const Catalog = preload("res://modules/spell/catalog.gd")
var model: Node
var graph: GraphEdit
var skill: OptionButton
var gem: OptionButton
var quality: SpinBox
var status: Label
var json_text: TextEdit
var link_source := -1
var disconnect_mode := false
var link_hint: Label
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
 title.text="自由寶石連鎖｜先點起點，再點目標；也可拖曳連線"
 box.add_child(title)
 var bar:=HBoxContainer.new()
 box.add_child(bar)
 skill=OptionButton.new()
 skill.custom_minimum_size.y=72
 for key in Catalog.PLAYABLE:
  skill.add_item(Zh.spell(key))
  skill.set_item_metadata(skill.item_count-1,key)
 bar.add_child(skill)
 gem=OptionButton.new()
 gem.custom_minimum_size.y=72
 for key in Catalog.data.GEM:
  gem.add_item(Zh.gem(key))
  gem.set_item_metadata(gem.item_count-1,key)
  gem.set_item_tooltip(gem.item_count-1,str(Catalog.data.GEM[key][2]))
 bar.add_child(gem)
 var quality_label:=Label.new();quality_label.text="品質";bar.add_child(quality_label)
 quality=SpinBox.new();quality.custom_minimum_size=Vector2(100,72);quality.min_value=1;quality.max_value=3;quality.value=3
 bar.add_child(quality)
 button("Add",bar,func():remember();model.add_node(str(skill.get_item_metadata(skill.selected)),str(gem.get_item_metadata(gem.selected)),int(quality.value));rebuild())
 button("Remove",bar,func():remember();model.remove_node(chosen);rebuild())
 button("Done",bar,func():closed.emit())
 var link_bar:=HBoxContainer.new();box.add_child(link_bar)
 button("Link mode",link_bar,func():disconnect_mode=not disconnect_mode;cancel_link();action_buttons["Link mode"].text="連線模式：移除" if disconnect_mode else "連線模式：新增")
 action_buttons["Link mode"].text="連線模式：新增"
 button("Cancel link",link_bar,cancel_link)
 link_hint=Label.new();link_hint.size_flags_horizontal=Control.SIZE_EXPAND_FILL;link_hint.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;link_bar.add_child(link_hint)
 var tools:=HBoxContainer.new();box.add_child(tools)
 button("Demo",tools,func():remember();model.demo();rebuild())
 button("Undo",tools,undo)
 button("Redo",tools,redo)
 button("Export JSON",tools,func():json_text.text=JSON.stringify(model.build(),"  "))
 button("Import JSON",tools,func():
  var parsed: Variant=JSON.parse_string(json_text.text)
  var before: Dictionary=model.build()
  if model.restore(parsed):
   history.append(before);future.clear();rebuild();status.text="配置匯入成功"
  else:status.text="匯入失敗：格式有誤、包含未支援法術，或存在循環連線。"
 )
 for move in [["Pan left","左移",Vector2(-240,0)],["Pan right","右移",Vector2(240,0)],["Pan up","上移",Vector2(0,-240)],["Pan down","下移",Vector2(0,240)]]:
  var step: Vector2=move[2]
  button(str(move[0]),tools,func():graph.scroll_offset+=step)
  action_buttons[move[0]].text=move[1]
  action_buttons[move[0]].custom_minimum_size.x=88
 graph=GraphEdit.new()
 graph.custom_minimum_size=Vector2(400,260)
 graph.size_flags_vertical=Control.SIZE_EXPAND_FILL
 box.add_child(graph)
 graph.connection_request.connect(func(from:StringName,_port:int,to:StringName,_to_port:int):remember();model.connect_nodes(int(String(from)),int(String(to)));rebuild())
 graph.disconnection_request.connect(func(from:StringName,_port:int,to:StringName,_to_port:int):remember();model.disconnect_nodes(int(String(from)),int(String(to)));rebuild())
 graph.add_theme_constant_override("port_hotzone_inner_extent",24)
 graph.add_theme_constant_override("port_hotzone_outer_extent",24)
 graph.node_selected.connect(func(node:Node):chosen=int(String(node.name)))
 graph.begin_node_move.connect(remember)
 graph.end_node_move.connect(func():
  for child in graph.get_children():
   if child is GraphNode:
    var data: Dictionary=model.find(int(String(child.name)))
    if not data.is_empty():data.x=child.position_offset.x;data.y=child.position_offset.y
 )
 status=Label.new();box.add_child(status)
 json_text=TextEdit.new();json_text.custom_minimum_size=Vector2(0,72);json_text.placeholder_text="貼上配置文字即可匯入；舊版 HTML 的連鎖配置暫不支援。";box.add_child(json_text)
 rebuild()
func button(text:String,parent:Node,action:Callable) -> void:
 var b:=Button.new();b.text=Zh.ui(text);b.custom_minimum_size=Vector2(112,72);parent.add_child(b);b.pressed.connect(action);action_buttons[text]=b
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
 cancel_link()
 for key in action_buttons.keys():
  if str(key).begins_with("Source ") or str(key).begins_with("Target "):action_buttons.erase(key)
 graph.clear_connections()
 for child in graph.get_children():
  if child is GraphNode:
   graph.remove_child(child);child.queue_free()
 for data in model.nodes:
  var node:=GraphNode.new()
  node.name=str(int(data.id));node.title=Zh.spell(str(data.key))
  node.position_offset=Vector2(float(data.x),float(data.y))
  var node_style:=StyleBoxFlat.new()
  node_style.bg_color=Color("202e44")
  node_style.border_color=Color("6687a2")
  node_style.set_border_width_all(1)
  node.add_theme_stylebox_override("panel",node_style)
  var label:=Label.new();label.text="輸入　＞　輸出\n%s・品質 %d" % [Zh.gem(str(data.gem)),int(data.quality)];label.custom_minimum_size=Vector2(200,72);node.add_child(label)
  var touch_row:=HBoxContainer.new();node.add_child(touch_row)
  var id:=int(data.id)
  button("Source %d" % id,touch_row,func():choose_source(id))
  action_buttons["Source %d" % id].text="起點"
  action_buttons["Source %d" % id].custom_minimum_size.x=96
  action_buttons["Source %d" % id].toggle_mode=true
  button("Target %d" % id,touch_row,func():apply_target.call_deferred(id))
  action_buttons["Target %d" % id].text="目標"
  action_buttons["Target %d" % id].custom_minimum_size.x=96
  node.set_slot(0,true,0,Color("89e6ff"),true,0,Color("ffd484"))
  graph.add_child(node)
 for edge in model.edges:graph.connect_node(str(int(edge.from)),0,str(int(edge.to)),0)
 status.text="%d 個節點／%d 條連線・寶石品質 1～3・安全上限：16 層／240 次觸發" % [model.nodes.size(),model.edges.size()]

func cancel_link() -> void:
 link_source=-1
 for key in action_buttons:
  if str(key).begins_with("Source "):action_buttons[key].set_pressed_no_signal(false)
 if is_instance_valid(link_hint):link_hint.text="選擇節點的起點，再選目標；取消不會改動配置。"

func choose_source(id: int) -> void:
 if model.find(id).is_empty():cancel_link();return
 if link_source==id:cancel_link();return
 cancel_link()
 link_source=id
 action_buttons["Source %d" % id].set_pressed_no_signal(true)
 link_hint.text="起點：%s。請點目標以%s連線。" % [Zh.spell(str(model.find(id).key)),"移除" if disconnect_mode else "新增"]

func apply_target(id: int) -> void:
 if link_source<0:
  link_hint.text="請先選擇起點。";return
 var before: Dictionary=model.build()
 var success:=false
 if disconnect_mode:
  if model.edges.has({"from":link_source,"to":id}):
   model.disconnect_nodes(link_source,id);success=true
 else:success=model.connect_nodes(link_source,id)
 if not success:
  link_hint.text="無法連線：不可循環、重複或連到自己；移除時需已有連線。";return
 history.append(before);future.clear()
 if history.size()>40:history.pop_front()
 rebuild()
 link_hint.text="連線已移除，可復原。" if disconnect_mode else "連線已新增，可復原。"
