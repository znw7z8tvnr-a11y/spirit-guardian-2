extends CanvasLayer
signal pause_requested
signal speed_requested
signal wave_requested
signal restart_requested
signal element_selected(element: StringName)
var status: Label
var health: ProgressBar
var pause_button: Button
var speed_button: Button
var message: Label
var wave_button: Button
var buttons := {}
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
 title.text = "SPIRIT GUARDIAN  /  M1"
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
 note.text = "TEMP ART • Core combat prototype • No full save yet"
 note.add_theme_font_size_override("font_size", 14)
 top.add_child(note)
 var bottom := VBoxContainer.new()
 bottom.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
 bottom.offset_left = 24
 bottom.offset_right = -24
 bottom.offset_top = -156
 bottom.offset_bottom = -24
 bottom.alignment = BoxContainer.ALIGNMENT_END
 root.add_child(bottom)
 message = Label.new()
 message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 bottom.add_child(message)
 var elements := HBoxContainer.new()
 elements.alignment = BoxContainer.ALIGNMENT_CENTER
 bottom.add_child(elements)
 for element in ["fire", "ice", "lightning", "arcane"]:
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
 button.text = text
 button.custom_minimum_size = Vector2(112, 48)
 button.add_theme_font_size_override("font_size", 18)
 parent.add_child(button)
 return button

func update_status(wave: int, kills: int, hp: float, selected: StringName) -> void:
 status.text = "Wave %d   /   Kills %d   /   Crystal %d / 100   /   %s" % [wave, kills, hp, String(selected).capitalize()]
 health.value = hp
