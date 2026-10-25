extends Control
## Product flow owns navigation and progress; the shared battle owns gameplay.
const BattleScene = preload("res://game/battle/battle_scene.tscn")
const Background = preload("res://content/ui/player/background.png")
const Atlas = preload("res://content/ui/player/atlas.png")
const Preview = preload("res://game/player/map_preview.gd")
const Catalog = preload("res://game/content/content_catalog.gd")
const Progress = preload("res://game/player/campaign_progress.gd")
const Session = preload("res://features/story/story_session.gd")
const StoryView = preload("res://features/story/story_view.gd")
const DESIGN_SIZE := Vector2(1672, 941)
@export var save_path := "user://player_progress.cfg"
var page := ""
var menu: Control
var canvas: Control
var battle_scene: Node3D
var has_progress := false
var completed := false
var save_notice := ""
var catalog = Catalog.new()
var progress = Progress.new()
var session = Session.new()
var story_view: Control
var story_kind := ""
var story_level := ""
var result_recorded := false
var return_button: Button
var tutorial: PanelContainer
var tutorial_seen := false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	catalog.reload()
	_load_progress()
	resized.connect(_fit_menu)
	show_main()

func _load_progress() -> void:
	progress.load_progress(save_path, catalog.levels.keys())
	has_progress = progress.started or not progress.pending_after.is_empty()
	completed = progress.completed.size() == catalog.levels.size() and not catalog.levels.is_empty()

func _save_progress() -> void:
	var result: Error = progress.save(save_path)
	save_notice = "" if result == OK else "进度未能保存"
	has_progress = progress.started
	completed = progress.completed.size() == catalog.levels.size() and not catalog.levels.is_empty()

func resume_game() -> void:
	if not progress.pending_after.is_empty(): show_story(progress.pending_after, "after")
	else: show_levels()

func _clear_page() -> void:
	if is_instance_valid(menu):
		remove_child(menu)
		menu.queue_free()
	if is_instance_valid(battle_scene):
		remove_child(battle_scene)
		battle_scene.queue_free()
	battle_scene = null
	menu = null
	story_view = null
	return_button = null
	tutorial = null

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
	_button(canvas, "开始游戏", Rect2(85, 307, 450, 78), resume_game, true)
	var resume := _button(canvas, "读取存档", Rect2(85, 420, 450, 78), resume_game)
	resume.disabled = not has_progress
	_button(canvas, "退出游戏", Rect2(85, 533, 450, 78), func(): get_tree().quit())
	_image(canvas, Rect2(57, 659, 350, 35), _region(Rect2(35, 780, 275, 40)))
	if not has_progress: _text(canvas, "暂无存档", Rect2(90, 621, 430, 30), 19, Color("8fa8b7"))

func show_levels() -> void:
	_menu_page("levels", 0.67)
	_button(canvas, "‹", Rect2(30, 28, 90, 62), show_main)
	_text(canvas, "第一章 · 上海", Rect2(145, 27, 820, 75), 42)
	_text(canvas, "寻找失踪的小黄", Rect2(50, 128, 900, 48), 28, Color("b9d9e4"))
	_line(Vector2(50, 187), Vector2(1020, 187))
	if catalog.levels.is_empty():
		var issues := _text(canvas, "内容配置错误\n" + "\n".join(catalog.errors), Rect2(100, 250, 1400, 450), 22)
		issues.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		return
	var ids: Array = catalog.levels.keys()
	for i in ids.size():
		var id: String = ids[i]
		if not progress.unlocked(id, ids): continue
		var x := 90.0 + i * 315.0
		var node := _button(canvas, "✓" if progress.completed.has(id) else "%02d" % (i + 1), Rect2(x, 360, 205, 110), _select_level.bind(id), id == progress.selected)
		node.alignment = HORIZONTAL_ALIGNMENT_CENTER
		_text(canvas, catalog.levels[id].name, Rect2(x - 30, 505, 285, 65), 27).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_text(canvas, "已完成" if progress.completed.has(id) else "可行动", Rect2(x, 590, 205, 40), 23, Color("81ddea")).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_line(Vector2(30, 815), Vector2(1020, 815))
	if completed: _text(canvas, "第一章完成 · 小黄的信号来自海洋", Rect2(80, 710, 940, 60), 28, Color("dfc49b"))
	var level: Dictionary = catalog.levels[progress.selected]
	var detail := Panel.new()
	detail.position = Vector2(1090, 112); detail.size = Vector2(553, 777)
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.035, 0.075, 0.11, 0.90)
	panel_style.border_color = Color("83afc3"); panel_style.set_border_width_all(1)
	detail.add_theme_stylebox_override("panel", panel_style)
	canvas.add_child(detail)
	_add_preview(detail)
	_text(detail, level.name, Rect2(27, 295, 500, 65), 30)
	var description := _text(detail, level.description, Rect2(28, 375, 490, 95), 23, Color("b9d9e4"))
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text(detail, "出战干员", Rect2(28, 505, 450, 32), 22, Color("a7c3d1"))
	var roster: Array = level.roster.keys()
	for i in roster.size():
		var appearance = load(catalog.characters[roster[i]].appearance)
		_image(detail, Rect2(28 + i * 99, 550, 86, 83), appearance.portrait)
		_text(detail, level.roster[roster[i]].name, Rect2(28 + i * 99, 633, 86, 28), 18).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var action := _button(detail, "开始行动   ›", Rect2(25, 689, 505, 65), begin_action, true)
	action.name = "StartAction"
	var issues: PackedStringArray = catalog.diagnostics(progress.selected)
	action.disabled = not issues.is_empty()
	if not issues.is_empty():
		var error_label := _text(canvas, "\n".join(issues), Rect2(60, 670, 960, 120), 16, Color("ffbd9b"))
		error_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if not save_notice.is_empty(): _text(canvas, save_notice, Rect2(660, 865, 350, 28), 20, Color("ffbd9b"))

func _select_level(id: String) -> void:
	if not progress.unlocked(id, catalog.levels.keys()): return
	progress.selected = id
	show_levels()

func begin_action() -> void:
	if not progress.pending_after.is_empty():
		show_story(progress.pending_after, "after"); return
	if not progress.unlocked(progress.selected, catalog.levels.keys()): return
	if not catalog.diagnostics(progress.selected).is_empty(): return
	progress.started = true
	_save_progress()
	show_story(progress.selected, "before")

func show_story(id: String, kind: String) -> void:
	if not catalog.diagnostics(id).is_empty(): show_levels(); return
	_clear_page()
	page = "story"
	story_level = id; story_kind = kind
	menu = Control.new()
	menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(menu)
	story_view = StoryView.new()
	var textures: Dictionary = catalog.story_textures()
	story_view.configure(textures.backgrounds, textures.actors)
	menu.add_child(story_view)
	story_view.advance_requested.connect(advance_story)
	story_view.choice_requested.connect(func(_index: int): pass)
	var story = catalog.story(catalog.levels[id][kind])
	var issues: PackedStringArray = session.load_story(story)
	if not issues.is_empty():
		save_notice = "剧情配置错误"; show_levels(); return
	story_view.show_snapshot(session.snapshot())
	var toolbar := HBoxContainer.new()
	toolbar.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	toolbar.offset_left = -280; toolbar.offset_right = -20; toolbar.offset_top = 20
	menu.add_child(toolbar)
	for entry in [["返回关卡", show_levels], ["跳过剧情", finish_story]]:
		var button := Button.new(); button.text = entry[0]
		button.custom_minimum_size = Vector2(120, 44)
		button.add_theme_font_size_override("font_size", 20)
		button.pressed.connect(entry[1]); toolbar.add_child(button)

func advance_story() -> void:
	if page != "story": return
	if session.advance():
		if session.snapshot().finished: finish_story()
		else: story_view.show_snapshot(session.snapshot())

func finish_story() -> void:
	if page != "story": return
	if story_kind == "before":
		progress.selected = story_level
		start_battle()
	else:
		progress.finish_story(catalog.levels.keys())
		_save_progress()
		show_levels()

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
	var preview = Preview.new()
	preview.map_source = load(catalog.levels[progress.selected].map)
	viewport.add_child(preview)

func start_battle() -> void:
	if not progress.unlocked(progress.selected, catalog.levels.keys()): return
	if not catalog.diagnostics(progress.selected).is_empty(): return
	progress.started = true
	_save_progress()
	_clear_page()
	page = "battle"
	result_recorded = false
	battle_scene = BattleScene.instantiate()
	battle_scene.campaign_level = progress.selected
	battle_scene.exit_requested.connect(func(): show_levels.call_deferred())
	battle_scene.continue_requested.connect(func(): _leave_result.call_deferred())
	battle_scene.observed.connect(_observe_battle)
	add_child(battle_scene)
	if not battle_scene.battle:
		var back := Button.new(); back.text = "返回关卡"
		back.position = Vector2(30, 35); back.pressed.connect(show_levels)
		battle_scene.hud.add_child(back); return
	return_button = Button.new()
	return_button.text = "返回关卡"
	return_button.custom_minimum_size = Vector2(220, 48)
	return_button.add_theme_font_size_override("font_size", 22)
	return_button.pressed.connect(_leave_result)
	battle_scene.hud.end_panel.get_child(0).add_child(return_button)
	if progress.selected == "scene_002" and not tutorial_seen: _show_tutorial()

func _show_tutorial() -> void:
	tutorial_seen = true
	tutorial = PanelContainer.new()
	tutorial.position = Vector2(18, 96)
	tutorial.mouse_filter = Control.MOUSE_FILTER_STOP
	var column := VBoxContainer.new(); tutorial.add_child(column)
	var label := Label.new()
	label.text = "部署大星守住正面。\n小黄费用低，撤退后能很快再次部署。"
	label.add_theme_font_size_override("font_size", 18)
	column.add_child(label)
	var close := Button.new(); close.text = "知道了"
	close.pressed.connect(func(): tutorial.hide())
	column.add_child(close)
	battle_scene.hud.add_child(tutorial)

func _leave_result() -> void:
	if battle_scene and battle_scene.last_state.phase == "victory": show_story(progress.selected, "after")
	else: show_levels()

func _observe_battle(state: Dictionary, _events: Array) -> void:
	if state.phase == "ready": result_recorded = false
	if state.phase == "victory" and not result_recorded:
		result_recorded = true
		progress.pending_after = progress.selected
		_save_progress()
	if return_button:
		return_button.visible = state.phase == "defeat"
	if tutorial and state.phase in ["victory", "defeat"]: tutorial.hide()

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE and page == "levels":
		show_main()
		get_viewport().set_input_as_handled()
	elif page == "story" and event.is_action_pressed("ui_accept") and not event.is_echo():
		advance_story()
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
