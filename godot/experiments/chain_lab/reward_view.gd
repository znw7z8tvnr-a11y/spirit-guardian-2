extends PanelContainer
const Zh=preload("res://localization/zh_hant.gd")
var model: Node
var summary: Label
var choices: Array=[]
var refresh: Button
var input_locked:=false
const INPUT_GUARD_SECONDS=0.25
func _ready() -> void:
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);offset_left=16;offset_right=-16;offset_top=16;offset_bottom=-16
 var style:=StyleBoxFlat.new();style.bg_color=Color("182137");style.set_content_margin_all(24);add_theme_stylebox_override("panel",style)
 var scroll:=ScrollContainer.new();scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;add_child(scroll)
 var box:=VBoxContainer.new();box.size_flags_horizontal=Control.SIZE_EXPAND_FILL;scroll.add_child(box)
 var title:=Label.new();title.text="靈境贈禮｜選擇一項本局獎勵";box.add_child(title)
 summary=Label.new();summary.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;box.add_child(summary)
 refresh=Button.new();refresh.custom_minimum_size.y=72;box.add_child(refresh);refresh.pressed.connect(func():activate(-1))
 for i in range(3):
  var button:=Button.new();button.custom_minimum_size=Vector2(800,118);button.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;box.add_child(button);choices.append(button)
  button.pressed.connect(func():activate(i))
 var help:=Label.new();help.text="物品進入圖示背包，由你決定裝在哪一格；詞條立即生效。選擇期間戰鬥暫停。";help.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;box.add_child(help)
 hide()
func bind(rewards: Node) -> void:
 model=rewards;model.changed.connect(sync);sync()
func description(item: Dictionary) -> String:
 if item.kind=="skill":return "%s・%d 級\n攻擊技能｜%s" % [Zh.spell(str(item.key)),int(item.level),preload("res://experiments/chain_lab/spell_effects.gd").description(str(item.key))]
 if item.kind=="gem":return "%s・%d 級\n%s" % [preload("res://experiments/chain_lab/gem_rules.gd").title(str(item.key)),int(item.level),preload("res://experiments/chain_lab/gem_rules.gd").description(str(item.key),int(item.level))]
 return "再啟靈思｜本局之後每次獎勵多一次刷新" if item.key=="refresh" else "靈能增幅｜本局法術攻擊加成增加 10%"
func sync() -> void:
 visible=model.pending>0
 if not visible:return
 summary.text="尚有 %d 次選擇｜刷新詞條 %d 層｜法術詞條加成 +%d%%\n每次固定包含技能、寶石與詞條各一項；刷新不消耗已取得物品；整組至少一項內容不同，換順序不算，不保證升級。" % [model.pending,model.extra_refresh,model.attack_stacks*10]
 refresh.text="刷新選項（剩餘 %d 次）" % model.refreshes;refresh.disabled=input_locked or model.refreshes<=0
 for i in choices.size():
  choices[i].disabled=input_locked
  choices[i].text=description(model.offers[i])

func activate(index: int) -> bool:
 if not is_visible_in_tree() or input_locked or not is_instance_valid(model):return false
 if index< -1 or index>=model.offers.size():return false
 input_locked=true
 var accepted: bool=model.refresh_offer() if index== -1 else model.choose(index)
 if not accepted:
  input_locked=false;sync();return false
 sync()
 get_tree().create_timer(INPUT_GUARD_SECONDS,true,false,true).timeout.connect(unlock_input)
 return true
func unlock_input() -> void:
 input_locked=false
 if is_instance_valid(model):sync()
