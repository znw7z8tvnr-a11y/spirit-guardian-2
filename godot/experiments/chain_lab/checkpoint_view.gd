extends PanelContainer
signal resume_requested
signal new_run_requested
var heading: Label
var detail: Label
var resume: Button
var fresh: Button
func _ready() -> void:
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);offset_left=24;offset_right=-24;offset_top=24;offset_bottom=-24
 var bg:=StyleBoxFlat.new();bg.bg_color=Color("101a2c");bg.set_content_margin_all(24);add_theme_stylebox_override("panel",bg)
 var box:=VBoxContainer.new();box.add_theme_constant_override("separation",18);add_child(box)
 heading=Label.new();heading.add_theme_font_size_override("font_size",34);box.add_child(heading)
 detail=Label.new();detail.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;detail.size_flags_vertical=Control.SIZE_EXPAND_FILL;box.add_child(detail)
 resume=Button.new();resume.text="繼續波間進度";resume.custom_minimum_size.y=72;box.add_child(resume);resume.pressed.connect(func():resume_requested.emit())
 fresh=Button.new();fresh.text="重新開局・清除波間進度";fresh.custom_minimum_size.y=72;box.add_child(fresh);fresh.pressed.connect(func():new_run_requested.emit());hide()
func show_record(record: Dictionary) -> void:
 resume.disabled=not record.ok
 if record.ok:
  var data: Dictionary=record.data;var wave:=int(data.game.wave)
  heading.text="找到備份波間進度" if record.get("source","")=="backup" else "找到波間進度"
  var phase: String="領完末波獎勵後結算" if wave==20 else "下一波：%d／20" % (wave+1)
  detail.text="已完成第 %d 波｜%s\n尚有 %d 次獎勵選擇｜持有物品 %d 件\n核心 %d／%d｜城牆 %d／%d\n本局成長、配置、冷卻與獎勵會一起讀回。\n\n戰鬥中中斷會回到最近波間，不會原地恢復半途戰鬥。\n這份進度只在此瀏覽器／裝置保存。" % [wave,phase,int(data.rewards.pending),data.chain.items.size(),data.tower.hp,data.tower.max_hp,data.tower.wall_hp,data.tower.wall_max]
  if record.get("source","")=="backup":detail.text+="\n\n原進度無法讀取；繼續時使用較早備份。"
 else:
  heading.text="波間進度無法讀取"
  detail.text="進度格式不支援、資料損壞或驗證未通過。原檔會先保留，選擇重新開局才會清除。共振紀錄書不受影響。"
 show()
