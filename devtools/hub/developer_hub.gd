extends Control
## Developer-only navigation. Each complete card is a keyboard-accessible button.
const PATH = preload("res://devtools/ui/workspace_path.gd")
const ENTRIES = [
	{"title": "Player Mode", "category": "玩家入口", "number": "00", "accent": Color("83d8ec"),
		"description": "从主界面选择关卡，进入完整的玩家战斗流程。", "detail": "主界面 / 关卡选择 / 战斗",
		"scene": "res://game/player/player_mode.tscn"},
	{"title": "Blueprint", "category": "视觉方向", "number": "01", "accent": Color("cfb287"),
		"description": "查看与对比概念方案，确定战场的视觉方向。", "detail": "A / B 概念对比",
		"scene": "res://devtools/blueprint/blueprint_workspace.tscn"},
	{"title": "Art Test", "category": "素材检视", "number": "02", "accent": Color("7dc6ba"),
		"description": "浏览角色、特效与动画，检查战场组合效果。", "detail": "Character / Effect / Animation / Battle / Skill",
		"scene": "res://devtools/art_test/art_workspace.tscn"},
	{"title": "Game Test", "category": "集成预览", "number": "03", "accent": Color("b0a4cf"),
		"description": "在完整美术战场中部署干员，验证真实战斗流程。", "detail": "可编辑地图 / 完整战斗 / 内嵌调试",
		"scene": "res://devtools/game_test/game_workspace.tscn"},
	{"title": "Story Test", "category": "剧情验证", "number": "04", "accent": Color("deb58a"),
		"description": "运行基础剧情样例，检查对话推进、分支与结束。", "detail": "对话 / 分支选择 / 重播",
		"scene": "res://devtools/story_test/story_workspace.tscn"},
]
var scroll: ScrollContainer
var content: VBoxContainer
var workspaces: GridContainer

func _ready() -> void:
	RenderingServer.set_default_clear_color(Color("101b2a"))
	var background := ColorRect.new()
	background.color = Color("101923")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for edge in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + edge, 24)
	add_child(margin)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 16)
	margin.add_child(layout)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 16)
	layout.add_child(header)
	var breadcrumb := PATH.new()
	breadcrumb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(breadcrumb)
	breadcrumb.configure(PackedStringArray(["Star World", "Developer Hub"]))
	var player_button := Button.new()
	player_button.name = "PlayerModeShortcut"
	player_button.text = "进入 Player Mode →"
	player_button.custom_minimum_size = Vector2(230, 44)
	player_button.add_theme_font_size_override("font_size", 18)
	player_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	player_button.add_theme_stylebox_override("normal", card_style(Color("203440"), Color("568a9a")))
	player_button.add_theme_stylebox_override("hover", card_style(Color("2a4654"), Color("83d8ec")))
	player_button.add_theme_stylebox_override("pressed", card_style(Color("142b35"), Color("83d8ec")))
	player_button.add_theme_color_override("font_color", Color("bcecf7"))
	player_button.pressed.connect(_open_player)
	header.add_child(player_button)
	layout.add_child(divider())
	scroll = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(scroll)
	var center := CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(center)
	content = VBoxContainer.new()
	content.add_theme_constant_override("separation", 22)
	center.add_child(content)
	var heading := VBoxContainer.new()
	heading.add_theme_constant_override("separation", 8)
	content.add_child(heading)
	heading.add_child(spacer(10))
	text(heading, "S T A R   W O R L D   /   D E V E L O P M E N T", 12, Color("7dc6ba"))
	text(heading, "开发工作区", 34, Color("edf2f7"))
	var description := text(heading, "从视觉构想到规则验证，选择一个工作区开始。", 17, Color("99a9bb"))
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	heading.add_child(spacer(4))
	workspaces = GridContainer.new()
	workspaces.columns = 2
	workspaces.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	workspaces.add_theme_constant_override("h_separation", 18)
	workspaces.add_theme_constant_override("v_separation", 18)
	content.add_child(workspaces)
	for entry in ENTRIES:
		build_card(entry)
	var footer := VBoxContainer.new()
	footer.add_theme_constant_override("separation", 12)
	footer.add_child(divider())
	var note := text(footer, "开发流程   ·   独立验证  →  模块评审  →  游戏集成", 14, Color("8192a6"))
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(footer)
	scroll.resized.connect(_fit_layout)
	_fit_layout()

func _fit_layout() -> void:
	content.custom_minimum_size.x = maxf(0.0, minf(1160.0, scroll.size.x - 16.0))
	workspaces.columns = 2 if scroll.size.x >= 900.0 else 1

func build_card(entry: Dictionary) -> void:
	var button := Button.new()
	# Keep the accessible name and native focus/input behavior; the child layout draws the text.
	button.text = entry.title
	button.tooltip_text = entry.title + "：" + entry.description
	button.custom_minimum_size.y = 228
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		button.add_theme_color_override(state, Color.TRANSPARENT)
	button.add_theme_stylebox_override("normal", card_style(Color("182431"), Color("2c3b4c")))
	button.add_theme_stylebox_override("hover", card_style(Color("203140"), entry.accent.darkened(0.3)))
	button.add_theme_stylebox_override("pressed", card_style(Color("13232f"), entry.accent))
	var focus := card_style(Color.TRANSPARENT, entry.accent)
	focus.set_border_width_all(2)
	button.add_theme_stylebox_override("focus", focus)
	button.pressed.connect(func():
		if entry.title == "Player Mode": _open_player()
		else: get_tree().change_scene_to_file(entry.scene))
	workspaces.add_child(button)
	var inset := MarginContainer.new()
	inset.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for edge in ["left", "right", "top", "bottom"]:
		inset.add_theme_constant_override("margin_" + edge, 24)
	button.add_child(inset)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	inset.add_child(column)
	var top := HBoxContainer.new()
	column.add_child(top)
	var category := text(top, entry.category, 15, entry.accent)
	category.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text(top, entry.number, 15, Color("718298"))
	text(column, entry.title, 29, Color("edf2f7"))
	var description := text(column, entry.description, 16, Color("a6b5c6"))
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var spring := Control.new()
	spring.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(spring)
	var bottom := HBoxContainer.new()
	bottom.add_theme_constant_override("separation", 10)
	column.add_child(bottom)
	var detail := text(bottom, entry.detail, 13, Color("8195ab"))
	detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text(bottom, "进入  →", 15, entry.accent)
	ignore_pointer(inset)

func card_style(background: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(12)
	return style

func _open_player() -> void:
	_open_player_deferred.call_deferred()

func _open_player_deferred() -> void:
	var tree := get_tree()
	var player = load("res://game/player/player_mode.tscn").instantiate()
	player.developer_mode = true
	tree.root.remove_child(self)
	tree.root.add_child(player)
	tree.current_scene = player
	queue_free()

func text(parent: Node, value: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)
	return label

func divider() -> ColorRect:
	var line := ColorRect.new()
	line.color = Color("2a3746")
	line.custom_minimum_size.y = 1
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return line

func spacer(height: float) -> Control:
	var space := Control.new()
	space.custom_minimum_size.y = height
	return space

func ignore_pointer(node: Control) -> void:
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in node.get_children():
		if child is Control:
			ignore_pointer(child)
