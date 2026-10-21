extends Control
func _ready() -> void:
	var box = VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.offset_left = 32
	box.offset_top = 32
	box.offset_right = -32
	add_child(box)
	var back = Button.new()
	back.text = "< Developer Hub"
	back.pressed.connect(func(): get_tree().change_scene_to_file("res://devtools/hub/developer_hub.tscn"))
	box.add_child(back)
	var label = Label.new()
	label.text = "GAME TEST / 待集成\n\nAfter module review, assemble battle rules and art here."
	label.add_theme_font_size_override("font_size", 28)
	box.add_child(label)
