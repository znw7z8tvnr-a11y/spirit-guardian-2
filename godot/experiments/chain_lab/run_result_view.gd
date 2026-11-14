extends PanelContainer
## Read-only snapshot view; this screen never grants inventory or permanent power.
signal restart_requested
var heading: Label
var mode_label: Label
var details: Label
var restart: Button
var snapshot: Dictionary={}
func _ready() -> void:
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);offset_left=24;offset_top=24;offset_right=-24;offset_bottom=-24;mouse_filter=Control.MOUSE_FILTER_STOP
 var bg:=StyleBoxFlat.new();bg.bg_color=Color("101a2c");bg.border_color=Color("d1ae70");bg.set_border_width_all(2);bg.set_content_margin_all(24);add_theme_stylebox_override("panel",bg)
 var box:=VBoxContainer.new();box.add_theme_constant_override("separation",14);add_child(box)
 heading=Label.new();heading.add_theme_font_size_override("font_size",34);heading.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;box.add_child(heading)
 mode_label=Label.new();mode_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;box.add_child(mode_label)
 var scroll:=ScrollContainer.new();scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;box.add_child(scroll)
 details=Label.new();details.size_flags_horizontal=Control.SIZE_EXPAND_FILL;details.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;scroll.add_child(details)
 var note:=Label.new();note.text="當局血肉成長、物品與詞條不帶入下一局。共振紀錄書沿用既有保存規則。";note.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;box.add_child(note)
 restart=Button.new();restart.text="重新開始・奧彈開局";restart.custom_minimum_size.y=72;box.add_child(restart);restart.pressed.connect(func():restart_requested.emit());hide()
func show_result(data: Dictionary) -> void:
 snapshot=data.duplicate(true)
 heading.text="二十波守護成功" if data.outcome=="victory" else "守護水晶已破碎"
 mode_label.text="演練戰局・結果僅供測試" if data.training else "一般戰局・本局結算"
 details.text="完成波次　%d／20　　到達第 %d 波\n戰鬥時間　%d 分 %02d 秒（遊戲時間）\n擊殺　%d　　首領　%d／4\n法術施放　%d　　命中招數　%d　　落空招數　%d\n跳怪接力　%d　　共振　%d　　暴擊命中　%d\n血肉吸收　%d　　獎勵選擇　%d\n持有技能　%d　　寶石　%d\n核心生命　%d／%d　　城牆　%d／%d\n血肉強化　攻擊 %d　生命 %d　防禦 %d　回血 %d" % [data.cleared_waves,data.wave,int(data.seconds/60),int(data.seconds)%60,data.kills,data.boss_kills,data.casts,data.hits,data.misses,data.jumps,data.resonances,data.critical_victims,data.flesh_absorbed,data.awards,data.skills,data.gems,data.core,data.core_max,data.wall,data.wall_max,data.growth.atk,data.growth.hp,data.growth.armor,data.growth.regen]
 show()
