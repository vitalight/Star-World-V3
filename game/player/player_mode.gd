extends Control
## Product flow owns navigation and progress; the shared battle owns gameplay.
const BattleScene = preload("res://game/battle/battle_scene.tscn")
const Background = preload("res://content/ui/player/background.png")
const Atlas = preload("res://content/ui/player/atlas.png")
const Preview = preload("res://content/scenes/scene_001/preview.tscn")
const DESIGN_SIZE := Vector2(1672, 941)
@export var save_path := "user://player_progress.cfg"
var page := ""
var menu: Control
var canvas: Control
var battle_scene: Node3D
var has_progress := false
var completed := false
var save_notice := ""

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_load_progress()
	resized.connect(_fit_menu)
	show_main()

func _load_progress() -> void:
	var progress := ConfigFile.new()
	if progress.load(save_path) == OK:
		has_progress = progress.get_value("progress", "selected_level", "") == "scene_001"
		completed = has_progress and progress.get_value("progress", "scene_001_completed", false) == true

func _save_progress() -> void:
	var progress := ConfigFile.new()
	progress.set_value("progress", "selected_level", "scene_001")
	progress.set_value("progress", "scene_001_completed", completed)
	var result := progress.save(save_path)
	save_notice = "" if result == OK else "进度未能保存"

func _clear_page() -> void:
	if is_instance_valid(menu):
		remove_child(menu)
		menu.queue_free()
	if is_instance_valid(battle_scene):
		remove_child(battle_scene)
		battle_scene.queue_free()
	battle_scene = null
	menu = null

func _menu_page(kind: String, shade: float) -> void:
	_clear_page()
	page = kind
	menu = Control.new()
	menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(menu)
	var background := TextureRect.new()
	background.texture = Background
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	menu.add_child(background)
	var tint := ColorRect.new()
	tint.color = Color(0.015, 0.035, 0.055, shade)
	tint.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	menu.add_child(tint)
	canvas = Control.new()
	canvas.size = DESIGN_SIZE
	canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	menu.add_child(canvas)
	_fit_menu()

func _fit_menu() -> void:
	if not is_instance_valid(menu): return
	var ratio := minf(size.x / DESIGN_SIZE.x, size.y / DESIGN_SIZE.y)
	canvas.scale = Vector2.ONE * ratio
	canvas.position = (size - DESIGN_SIZE * ratio) * 0.5

func show_main() -> void:
	_menu_page("main", 0.0)
	_image(canvas, Rect2(74, 50, 170, 230), _region(Rect2(675, 685, 215, 235)))
	_button(canvas, "开始游戏", Rect2(85, 307, 450, 78), show_levels, true)
	var resume := _button(canvas, "读取存档", Rect2(85, 420, 450, 78), show_levels)
	resume.disabled = not has_progress
	_button(canvas, "退出游戏", Rect2(85, 533, 450, 78), func(): get_tree().quit())
	_image(canvas, Rect2(57, 659, 350, 35), _region(Rect2(35, 780, 275, 40)))
	if not has_progress: _text(canvas, "暂无存档", Rect2(90, 621, 430, 30), 19, Color("8fa8b7"))

func show_levels() -> void:
	_menu_page("levels", 0.67)
	_button(canvas, "‹", Rect2(30, 28, 90, 62), show_main)
	_text(canvas, "关卡选择", Rect2(145, 27, 500, 75), 42)
	_text(canvas, "行 动 区 域", Rect2(50, 128, 900, 48), 28, Color("b9d9e4"))
	_line(Vector2(50, 187), Vector2(1020, 187))
	# The route panel deliberately lists only authored playable content.
	var route := Line2D.new()
	route.points = PackedVector2Array([Vector2(115, 625), Vector2(305, 525), Vector2(470, 470), Vector2(725, 395), Vector2(940, 290)])
	route.width = 2
	route.default_color = Color(0.4, 0.8, 0.9, 0.23)
	canvas.add_child(route)
	var halo := Panel.new()
	halo.position = Vector2(345, 345); halo.size = Vector2(250, 250)
	var halo_style := StyleBoxFlat.new()
	halo_style.bg_color = Color(0.2, 0.8, 0.9, 0.04)
	halo_style.border_color = Color(0.5, 0.9, 1, 0.35)
	halo_style.set_border_width_all(1); halo_style.set_corner_radius_all(125)
	halo.add_theme_stylebox_override("panel", halo_style)
	halo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(halo)
	var diamond := Polygon2D.new()
	diamond.polygon = PackedVector2Array([Vector2(470, 380), Vector2(560, 470), Vector2(470, 560), Vector2(380, 470)])
	diamond.color = Color(0.12, 0.26, 0.32, 0.9)
	canvas.add_child(diamond)
	var outline := Line2D.new()
	outline.points = PackedVector2Array([Vector2(470, 380), Vector2(560, 470), Vector2(470, 560), Vector2(380, 470), Vector2(470, 380)])
	outline.width = 3; outline.default_color = Color("87e0ee")
	canvas.add_child(outline)
	var node := _button(canvas, "✓" if completed else "01", Rect2(410, 410, 120, 120), func(): _focus_action())
	node.alignment = HORIZONTAL_ALIGNMENT_CENTER
	for state in ["normal", "hover", "pressed"]: node.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	node.add_theme_font_size_override("font_size", 42)
	_text(canvas, "01 · 防线", Rect2(315, 620, 310, 50), 35).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_text(canvas, "已完成" if completed else "待行动", Rect2(315, 680, 310, 32), 23, Color("81ddea")).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_line(Vector2(30, 815), Vector2(1020, 815))
	_button(canvas, "‹   返回", Rect2(30, 842, 225, 63), show_main)
	var detail := Panel.new()
	detail.position = Vector2(1090, 112); detail.size = Vector2(553, 777)
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.035, 0.075, 0.11, 0.90)
	panel_style.border_color = Color("83afc3"); panel_style.set_border_width_all(1)
	detail.add_theme_stylebox_override("panel", panel_style)
	canvas.add_child(detail)
	_add_preview(detail)
	_text(detail, "01 · 防线", Rect2(27, 301, 500, 65), 42)
	_text(detail, "任务目标", Rect2(28, 397, 150, 35), 23, Color("a7c3d1"))
	_text(detail, "抵御全部敌人", Rect2(195, 397, 320, 35), 24)
	_text(detail, "行动状态", Rect2(28, 456, 150, 35), 23, Color("a7c3d1"))
	_text(detail, "已完成" if completed else "可出击", Rect2(195, 456, 320, 35), 24, Color("85dfed"))
	_text(detail, "出战干员", Rect2(28, 535, 450, 32), 22, Color("a7c3d1"))
	var ids := ["001", "003", "004", "005", "006"]
	for i in ids.size():
		_image(detail, Rect2(28 + i * 99, 580, 86, 70), load("res://content/characters/character_%s/portrait.tres" % ids[i]))
	var action := _button(detail, "开始行动   ›", Rect2(25, 671, 505, 77), start_battle, true)
	action.name = "StartAction"
	if not save_notice.is_empty(): _text(canvas, save_notice, Rect2(660, 865, 350, 28), 20, Color("ffbd9b"))

func _focus_action() -> void:
	canvas.find_child("StartAction", true, false).grab_focus()

func _add_preview(parent: Control) -> void:
	var container := SubViewportContainer.new()
	container.position = Vector2(22, 32); container.size = Vector2(510, 248)
	container.stretch = true
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(container)
	var viewport := SubViewport.new()
	viewport.size = Vector2i(510, 248)
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	container.add_child(viewport)
	viewport.add_child(Preview.instantiate())

func start_battle() -> void:
	has_progress = true
	_save_progress()
	_clear_page()
	page = "battle"
	battle_scene = BattleScene.instantiate()
	battle_scene.exit_requested.connect(func(): show_levels.call_deferred())
	battle_scene.observed.connect(_observe_battle)
	add_child(battle_scene)
	var back := Button.new()
	back.text = "返回关卡"
	back.custom_minimum_size = Vector2(220, 48)
	back.add_theme_font_size_override("font_size", 22)
	back.pressed.connect(func(): show_levels.call_deferred())
	battle_scene.hud.end_panel.get_child(0).add_child(back)

func _observe_battle(state: Dictionary, _events: Array) -> void:
	if state.phase == "victory" and not completed:
		completed = true
		_save_progress()

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE and page == "levels":
		show_main()
		get_viewport().set_input_as_handled()

func _region(rect: Rect2) -> AtlasTexture:
	var texture := AtlasTexture.new()
	texture.atlas = Atlas; texture.region = rect
	return texture

func _image(parent: Node, rect: Rect2, texture: Texture2D) -> TextureRect:
	var image := TextureRect.new()
	image.position = rect.position; image.size = rect.size
	image.texture = texture
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(image)
	return image

func _text(parent: Node, value: String, rect: Rect2, font_size: int, color := Color("f2f5f7")) -> Label:
	var label := Label.new()
	label.text = value; label.position = rect.position; label.size = rect.size
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label

func _button(parent: Node, value: String, rect: Rect2, action: Callable, primary := false) -> Button:
	var button := Button.new()
	button.text = value; button.position = rect.position; button.size = rect.size
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.add_theme_font_size_override("font_size", 32)
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for state in ["normal", "hover", "pressed", "disabled"]:
		var style := StyleBoxTexture.new()
		style.texture = _region(Rect2(348, 194, 258, 80) if (primary or state in ["hover", "pressed"]) and state != "disabled" else Rect2(40, 194, 258, 80))
		style.texture_margin_left = 14; style.texture_margin_right = 14
		style.texture_margin_top = 12; style.texture_margin_bottom = 12
		style.content_margin_left = 36; style.content_margin_right = 20
		button.add_theme_stylebox_override(state, style)
	var focus := StyleBoxFlat.new()
	focus.bg_color = Color.TRANSPARENT; focus.border_color = Color("90ecff")
	focus.set_border_width_all(2)
	button.add_theme_stylebox_override("focus", focus)
	button.add_theme_color_override("font_disabled_color", Color("65747d"))
	button.pressed.connect(action)
	parent.add_child(button)
	return button

func _line(a: Vector2, b: Vector2) -> void:
	var line := Line2D.new()
	line.points = PackedVector2Array([a, b]); line.width = 1
	line.default_color = Color("668392")
	canvas.add_child(line)
