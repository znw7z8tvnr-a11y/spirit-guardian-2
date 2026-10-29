extends PanelContainer
signal apply_requested(id: int)
const Art=preload("res://modules/spell/projectile.gd")
const Zh=preload("res://localization/zh_hant.gd")
const Effects=preload("res://experiments/chain_lab/spell_effects.gd")
const Catalog=preload("res://modules/spell/catalog.gd")
var model: Node
var slot:=0
var candidate:=-1
var attack_boost:=1.0
var cards: Dictionary={}
var detail: Label
var apply: Button
var entries: GridContainer
var heading: Label
func _ready() -> void:
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 offset_left=16;offset_right=-16;offset_top=16;offset_bottom=-16
 var style:=StyleBoxFlat.new();style.bg_color=Color("101a2c");style.set_content_margin_all(20);add_theme_stylebox_override("panel",style)
 var scroll:=ScrollContainer.new();scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;add_child(scroll)
 var box:=VBoxContainer.new();box.size_flags_horizontal=Control.SIZE_EXPAND_FILL;scroll.add_child(box)
 heading=Label.new();box.add_child(heading)
 var row:=HBoxContainer.new();box.add_child(row)
 var close:=Button.new();close.text="返回連鎖樹";close.custom_minimum_size=Vector2(220,72);close.pressed.connect(hide);row.add_child(close);cards["InventoryClose"]=close
 apply=Button.new();apply.text="確認替換";apply.custom_minimum_size=Vector2(220,72);apply.pressed.connect(func():apply_requested.emit(candidate));row.add_child(apply);cards["InventoryApply"]=apply
 detail=Label.new();detail.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;detail.custom_minimum_size.y=130;box.add_child(detail)
 entries=GridContainer.new();entries.columns=5;box.add_child(entries)
 hide()
func title(item: Dictionary) -> String:
 if item.is_empty():return "空格"
 return "%s・%d 級" % [Zh.spell(str(item.key)) if item.kind=="skill" else preload("res://experiments/chain_lab/gem_rules.gd").title(str(item.key)),int(item.level)]
func stats(item: Dictionary) -> String:
 if item.is_empty():return "無攻擊或接續效果"
 if item.kind=="gem":return preload("res://experiments/chain_lab/gem_rules.gd").description(str(item.key),int(item.level))
 return "直擊基礎傷害 %.1f（含血肉攻擊加成；範圍與狀態效果另計）" % (Effects.power(str(item.key),int(item.level),attack_boost))
func open(chain: Node, index: int, boost: float) -> void:
 model=chain;slot=index;attack_boost=boost
 heading.text="本局背包｜替換第 %d 格｜點物品預覽，再確認" % (slot+1)
 for key in cards.keys():
  if str(key).begins_with("Item "):cards.erase(key)
 for child in entries.get_children():entries.remove_child(child);child.queue_free()
 for id in range(-1,model.items.size()):
  var item: Dictionary={} if id<0 else model.items[id]
  var b:=Button.new();b.custom_minimum_size=Vector2(220,126);entries.add_child(b);cards["Item %d" % id]=b
  var owner: int=model.slots.find(id) if id>=0 else -1
  var state: String="清空" if id<0 else ("目前此格" if owner==slot else ("第 %d 格使用中" % (owner+1) if owner>=0 else "背包可用"))
  b.text="\n\n%s\n%s" % [title(item),state]
  b.add_theme_font_size_override("font_size",19)
  if id>=0:
   var art:=TextureRect.new();art.mouse_filter=Control.MOUSE_FILTER_IGNORE;art.position=Vector2(82,4);art.size=Vector2(56,56);art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
   art.texture=load("res://experiments/chain_lab/assets/relay_gem.svg") if item.kind=="gem" else Effects.texture(str(item.key));b.add_child(art)
   if item.kind=="gem":art.modulate=preload("res://experiments/chain_lab/gem_rules.gd").tint(str(item.key))
  b.pressed.connect(func():select_item(id))
 select_item(int(model.slots[slot]));show()
func select_item(id: int) -> void:
 candidate=id
 var item: Dictionary={} if id<0 else model.items[id]
 var reason: String=model.equipment_error(slot,id)
 detail.text="目前：%s｜%s\n候選：%s｜%s\n%s" % [title(model.item_at(slot)),stats(model.item_at(slot)),title(item),stats(item)+("；"+Effects.description(str(item.key)) if item.get("kind","")=="skill" else ""),"可以替換；容量及其他物品不變。" if reason.is_empty() else reason]
 apply.disabled=not reason.is_empty() or int(model.slots[slot])==id
 for key in cards:
  if str(key).begins_with("Item "):cards[key].modulate=Color("ffe3a0") if key=="Item %d" % id else Color.WHITE
