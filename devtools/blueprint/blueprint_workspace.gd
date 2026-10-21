extends Control
const UI = preload("res://devtools/ui/workspace_style.gd")
const ACCENT = Color("cfb287")
var preview: TextureRect
var caption: Label
var choices: Array[Button] = []

func _ready() -> void:
	var box := UI.shell(self, "Blueprint", ACCENT)
	UI.heading(box, "视觉方向", "对比两版概念，检查地形、道路与战场构图。", ACCENT)
	var bar := HFlowContainer.new()
	box.add_child(bar)
	var group := ButtonGroup.new()
	for index in 2:
		var button := Button.new()
		button.text = ["A / Sunlit quarry", "B / Waterway at night"][index]
		button.toggle_mode = true
		button.button_group = group
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.pressed.connect(_show_version.bind(index))
		bar.add_child(button)
		choices.append(button)
	var panel := PanelContainer.new()
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(panel)
	preview = TextureRect.new()
	preview.custom_minimum_size.y = 160
	preview.size_flags_vertical = Control.SIZE_EXPAND_FILL
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	panel.add_child(preview)
	caption = UI.text(box, "", 18, UI.INK)
	UI.text(box, "待选择  ·  两版原图与生成提示词均已保留。", 14)
	_show_version(0)

func _show_version(index: int) -> void:
	preview.texture = load(["res://devtools/blueprint/images/concept_a.png", "res://devtools/blueprint/images/concept_b.png"][index])
	caption.text = ["A · 日照采石场  /  砂岩阶地与蜿蜒道路", "B · 夜间水渠  /  岛屿、桥梁与 S 形路线"][index]
	choices[index].set_pressed_no_signal(true)
