extends PanelContainer
signal apply_requested(id: int)
const Filter=preload("res://experiments/chain_lab/inventory_filter.gd")
const Art=preload("res://modules/spell/projectile.gd")
const Zh=preload("res://localization/zh_hant.gd")
const Effects=preload("res://experiments/chain_lab/spell_effects.gd")
const Catalog=preload("res://modules/spell/catalog.gd")
var model: Node
var slot:=0
var candidate:=-1
var attack_boost:=1.0
var cards: Dictionary={}
var filters: Dictionary={}
var filter_mode:="all"
var filtered_ids: Array=[]
var empty_notice: Label
var detail: Label
var apply: Button
var entries: GridContainer
var heading: Label
var page:=0
const PAGE_SIZE=15
var page_label: Label
func _ready() -> void:
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 offset_left=16;offset_right=-16;offset_top=16;offset_bottom=-16
 var style:=StyleBoxFlat.new();style.bg_color=Color("101a2c");style.set_content_margin_all(20);add_theme_stylebox_override("panel",style)
 var scroll:=ScrollContainer.new();scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;add_child(scroll)
 var box:=VBoxContainer.new();box.size_flags_horizontal=Control.SIZE_EXPAND_FILL;scroll.add_child(box)
 heading=Label.new();box.add_child(heading)
 var row:=HBoxContainer.new();box.add_child(row)
 var close:=Button.new();close.text="返回連鎖樹";close.custom_minimum_size=Vector2(220,72);close.pressed.connect(hide);row.add_child(close);cards["InventoryClose"]=close
 apply=Button.new();apply.text="確認替換";apply.custom_minimum_size=Vector2(220,72);apply.pressed.connect(confirm_candidate);row.add_child(apply);cards["InventoryApply"]=apply
 detail=Label.new();detail.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;detail.custom_minimum_size.y=130;box.add_child(detail)
 var filter_row:=HBoxContainer.new();box.add_child(filter_row)
 for mode in Filter.MODES:
  var tab:=Button.new();tab.toggle_mode=true;tab.custom_minimum_size=Vector2(220,72);filter_row.add_child(tab);filters[mode]=tab;tab.pressed.connect(func():set_filter(mode))
 empty_notice=Label.new();empty_notice.text="這個分類目前沒有物品；可切換分類查看。";empty_notice.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;box.add_child(empty_notice)
 var paging:=HBoxContainer.new();box.add_child(paging)
 for direction in [-1,1]:
  var b:=Button.new();b.text="上一頁" if direction<0 else "下一頁";b.custom_minimum_size=Vector2(220,72);paging.add_child(b);cards["InventoryPrev" if direction<0 else "InventoryNext"]=b;b.pressed.connect(func():show_page(page+direction))
 page_label=Label.new();paging.add_child(page_label)
 entries=GridContainer.new();entries.columns=5;box.add_child(entries)
 visibility_changed.connect(func():
  if not visible:
   candidate=-2;apply.disabled=true
 )
 hide()
func title(item: Dictionary) -> String:
 if item.is_empty():return "空格"
 return "%s・%d 級" % [Zh.spell(str(item.key)) if item.kind=="skill" else preload("res://experiments/chain_lab/gem_rules.gd").title(str(item.key)),int(item.level)]
func stats(item: Dictionary) -> String:
 if item.is_empty():return "無攻擊或接續效果"
 if item.kind=="gem":
  var text: String=preload("res://experiments/chain_lab/gem_rules.gd").description(str(item.key),int(item.level))
  if item.key=="delay" and is_instance_valid(model):text+="｜目前冷卻 %.1f 秒" % (ceilf(model.gem_remaining(item)*10)/10)
  return text
 if is_instance_valid(model) and model.preceding_attack_scale(slot)>1:
  return "目前直擊傷害 %.1f（含血肉及後接攻擊寶石 +%d%%；不加成持續傷害）" % [Effects.power(str(item.key),int(item.level),attack_boost)*model.preceding_attack_scale(slot),roundi((model.preceding_attack_scale(slot)-1)*100)]
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
   art.texture=preload("res://experiments/chain_lab/gem_rules.gd").texture(str(item.key)) if item.kind=="gem" else Effects.texture(str(item.key));b.add_child(art)
   if item.kind=="gem":art.modulate=preload("res://experiments/chain_lab/gem_rules.gd").tint(str(item.key))
  b.pressed.connect(func():select_item(id))
 candidate=int(model.slots[slot]);set_filter("all",false);show()
func select_item(id: int) -> void:
 if id not in visible_item_ids():return
 candidate=id
 var item: Dictionary={} if id<0 else model.items[id]
 var reason: String=model.equipment_error(slot,id)
 detail.text="目前：%s｜%s\n候選：%s｜%s\n%s" % [title(model.item_at(slot)),stats(model.item_at(slot)),title(item),stats(item)+("；"+Effects.description(str(item.key)) if item.get("kind","")=="skill" else ""),"可以替換；容量及其他物品不變。" if reason.is_empty() else reason]
 apply.disabled=not reason.is_empty() or int(model.slots[slot])==id
 for key in cards:
  if str(key).begins_with("Item "):cards[key].modulate=Color("ffe3a0") if key=="Item %d" % id else Color.WHITE

func set_filter(mode: String,focus_candidate: bool=true) -> bool:
 if mode not in Filter.MODES or not is_instance_valid(model):return false
 filter_mode=mode;filtered_ids=Filter.ids(model,slot,mode)
 empty_notice.text="目前沒有可裝配的物品；可切換分類查看，或先調整連線。" if mode=="available" else "這個分類目前沒有物品；可切換分類查看。"
 var totals:=Filter.counts(model,slot)
 for key in filters:
  filters[key].text="%s %d" % [Filter.TITLES[key],totals[key]]
  filters[key].set_pressed_no_signal(key==mode)
 heading.text="本局背包｜替換第 %d 格｜%s｜點物品預覽，再確認" % [slot+1,Filter.TITLES[mode]]
 show_page(filtered_ids.find(candidate)/PAGE_SIZE if focus_candidate and candidate in filtered_ids else 0)
 if candidate in filtered_ids:select_item(candidate)
 else:
  candidate=-2;apply.disabled=true
  detail.text="目前：%s｜%s\n請點選此分類內的物品，再確認替換。" % [title(model.item_at(slot)),stats(model.item_at(slot))]
  for key in cards:
   if str(key).begins_with("Item "):cards[key].modulate=Color.WHITE
 return true
func confirm_candidate() -> void:
 if not visible or not is_instance_valid(model) or candidate not in visible_item_ids():return
 if int(model.slots[slot])==candidate or not model.equipment_error(slot,candidate).is_empty():set_filter(filter_mode);return
 apply_requested.emit(candidate)
func visible_item_ids() -> Array:
 return filtered_ids.slice(page*PAGE_SIZE,(page+1)*PAGE_SIZE)
func show_page(index: int) -> void:
 var count:=ceili(float(filtered_ids.size())/PAGE_SIZE)
 page=clampi(index,0,maxi(0,count-1))
 var visible_ids:=visible_item_ids()
 for key in cards:
  if str(key).begins_with("Item "):cards[key].visible=int(str(key).trim_prefix("Item ")) in visible_ids
 empty_notice.visible=filtered_ids.is_empty()
 page_label.text="%d／%d 頁" % [page+1 if count>0 else 0,count]
 cards.InventoryPrev.disabled=page==0;cards.InventoryNext.disabled=page>=count-1

 if candidate not in visible_ids:
  candidate=-2;apply.disabled=true
  detail.text="目前：%s｜%s\n請點選此分類內的物品，再確認替換。" % [title(model.item_at(slot)),stats(model.item_at(slot))]
  for key in cards:
   if str(key).begins_with("Item "):cards[key].modulate=Color.WHITE
