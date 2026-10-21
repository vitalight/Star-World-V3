extends Control
var preview: TextureRect
var caption: Label
func _ready() -> void:
	var box = VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.offset_left = 24
	box.offset_top = 24
	box.offset_right = -24
	box.offset_bottom = -24
	add_child(box)
	var bar = HBoxContainer.new()
	box.add_child(bar)
	var back = Button.new()
	back.text = "< Developer Hub"
	back.pressed.connect(func(): get_tree().change_scene_to_file("res://devtools/hub/developer_hub.tscn"))
	bar.add_child(back)
	for index in range(2):
		var button = Button.new()
		button.text = ["A / Sunlit quarry", "B / Waterway at night"][index]
		button.pressed.connect(_show_version.bind(index))
		bar.add_child(button)
	caption = Label.new()
	caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	caption.add_theme_font_size_override("font_size", 22)
	box.add_child(caption)
	preview = TextureRect.new()
	preview.size_flags_vertical = Control.SIZE_EXPAND_FILL
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	box.add_child(preview)
	_show_version(0)
func _show_version(index: int) -> void:
	preview.texture = load(["res://devtools/blueprint/images/concept_a.png", "res://devtools/blueprint/images/concept_b.png"][index])
	caption.text = ["BLUEPRINT / A — Sunlit quarry: stepped sandstone terraces and a winding lane.", "BLUEPRINT / B — Waterway at night: islands, bridges and an S-shaped route."][index] + "\nAwaiting your A / B choice. Both originals and prompts are preserved."
