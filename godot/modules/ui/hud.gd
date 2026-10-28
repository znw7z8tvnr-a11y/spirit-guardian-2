extends CanvasLayer
const Zh = preload("res://localization/zh_hant.gd")
signal pause_requested
signal speed_requested
signal wave_requested
signal restart_requested
signal diagnostic_tick(delta: float)
signal chain_requested
signal audio_requested
signal element_selected(element: StringName)
var boss_status: Label
var status: Label
var health: ProgressBar
var pause_button: Button
var speed_button: Button
var message: Label
var wave_button: Button
var buttons := {}
var extra_row: HBoxContainer
var root: Control

func _ready() -> void:
 root = Control.new()
 root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 root.mouse_filter = Control.MOUSE_FILTER_IGNORE
 add_child(root)
 var top := VBoxContainer.new()
 top.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
 top.offset_left = 24
 top.offset_right = -24
 top.offset_top = 24
 root.add_child(top)
 var title := Label.new()
 title.text = "靈境守衛｜M2 繁中試玩"
 title.add_theme_font_size_override("font_size", 24)
 top.add_child(title)
 status = Label.new()
 top.add_child(status)
 health = ProgressBar.new()
 health.custom_minimum_size = Vector2(320, 16)
 health.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
 health.show_percentage = false
 top.add_child(health)
 var note := Label.new()
 note.text = "暫用美術・目前僅儲存連鎖配置"
 note.add_theme_font_size_override("font_size", 14)
 top.add_child(note)
 boss_status=Label.new()
 boss_status.add_theme_color_override("font_color",Color("ffa3b7"))
 top.add_child(boss_status)
 var bottom := VBoxContainer.new()
 bottom.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
 bottom.offset_left = 24
 bottom.offset_right = -24
 bottom.offset_top = -208
 bottom.offset_bottom = -24
 bottom.alignment = BoxContainer.ALIGNMENT_END
 root.add_child(bottom)
 extra_row = HBoxContainer.new()
 extra_row.alignment = BoxContainer.ALIGNMENT_CENTER
 bottom.add_child(extra_row)
 make_button("Chain",extra_row).pressed.connect(func():chain_requested.emit())
 make_button("Audio: off",extra_row).pressed.connect(func():audio_requested.emit())
 message = Label.new()
 message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 bottom.add_child(message)
 var elements := HBoxContainer.new()
 elements.alignment = BoxContainer.ALIGNMENT_CENTER
 bottom.add_child(elements)
 for element in ["fire", "ice", "lightning", "arcane", "poison", "meteor", "nova", "beam"]:
  var button := make_button(element.capitalize(), elements)
  button.pressed.connect(func(): element_selected.emit(StringName(element)))
 var controls := HBoxContainer.new()
 controls.alignment = BoxContainer.ALIGNMENT_CENTER
 bottom.add_child(controls)
 pause_button = make_button("Pause", controls)
 pause_button.pressed.connect(func(): pause_requested.emit())
 speed_button = make_button("1x", controls)
 speed_button.pressed.connect(func(): speed_requested.emit())
 wave_button = make_button("Next wave", controls)
 wave_button.pressed.connect(func(): wave_requested.emit())
 make_button("Restart", controls).pressed.connect(func(): restart_requested.emit())

func make_button(text: String, parent: Node) -> Button:
 var button := Button.new()
 buttons[text] = button
 button.text = Zh.ui(text)
 button.custom_minimum_size = Vector2(112, 48)
 button.add_theme_font_size_override("font_size", 18)
 parent.add_child(button)
 return button

func update_status(wave: int, kills: int, hp: float, selected: StringName) -> void:
 status.text = "第 %d 波　／　擊殺 %d　／　水晶生命 %d／100　／　%s" % [wave, kills, hp, Zh.spell(String(selected))]
 health.value = hp

func _process(delta: float) -> void:
 diagnostic_tick.emit(delta)
