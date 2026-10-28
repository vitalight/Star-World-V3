extends Control
## Product flow owns navigation and progress; the shared battle owns gameplay.
const BattleScene = preload("res://game/battle/battle_scene.tscn")
const Background = preload("res://content/ui/player/background.png")
const Atlas = preload("res://content/ui/player/atlas.png")
const MainBackground = preload("res://content/ui/player/main_background_v2.png")
const MainEmblem = preload("res://content/ui/player/main_emblem_v2.png")
const MainButtonLight = preload("res://content/ui/player/main_button_light_v2.png")
const MainButtonDark = preload("res://content/ui/player/main_button_dark_v2.png")
const MainSettings = preload("res://content/ui/player/main_settings_v2.png")
const Preview = preload("res://game/player/map_preview.gd")
const Catalog = preload("res://game/content/content_catalog.gd")
const Progress = preload("res://game/player/campaign_progress.gd")
const Session = preload("res://features/story/story_session.gd")
const StoryView = preload("res://features/story/story_view.gd")
const AudioDirector = preload("res://features/audio/audio_director.gd")
const AudioSettings = preload("res://features/audio/audio_settings.gd")
const Cues = preload("res://content/audio/cues.tres")
const DESIGN_SIZE := Vector2(1672, 941)
@export var save_path := "user://player_progress.cfg"
@export var audio_settings_path := "user://audio_settings.cfg"
var page := ""
var menu: Control
var canvas: Control
var battle_scene: Node3D
var has_progress := false
var completed := false
var save_notice := ""
var catalog = Catalog.new()
var progress = Progress.new()
var audio: Node
var audio_settings
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
	_setup_audio()
	resized.connect(_fit_menu)
	show_main()

func _setup_audio() -> void:
	audio_settings = AudioSettings.new()
	audio_settings.load_settings(audio_settings_path)
	audio = AudioDirector.new()
	audio.set_library(Cues)
	audio.apply_settings(audio_settings)
	add_child(audio)

func _play_music(id: String) -> void:
	if audio: audio.play_music(id)

func _play_ui(id: String) -> void:
	if audio: audio.play_sfx(id)

func _load_progress() -> void:
	progress.load_progress(save_path, catalog.levels.keys())
	progress.configure_operators(catalog.starting_operators, catalog.recruits, catalog.characters.keys(), catalog.departures, catalog.returns)
	has_progress = progress.started or not progress.pending_after.is_empty()
	completed = progress.completed.size() == catalog.levels.size() and not catalog.levels.is_empty()

func _save_progress() -> void:
	var result: Error = progress.save(save_path)
	save_notice = "" if result == OK else "进度未能保存"
	has_progress = progress.started
	completed = progress.completed.size() == catalog.levels.size() and not catalog.levels.is_empty()

func resume_game() -> void:
	if not progress.pending_after.is_empty(): _continue_campaign()
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
	background.texture = MainBackground if kind == "main" else Background
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
	_play_music("music_main")
	_image(canvas, Rect2(528, 95, 616, 427), MainEmblem)
	var title := _text(canvas, "星世界", Rect2(570, 226, 532, 172), 110, Color("f8f9ff"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_shadow_color", Color("253d79"))
	title.add_theme_constant_override("shadow_offset_x", 4)
	title.add_theme_constant_override("shadow_offset_y", 6)
	title.add_theme_constant_override("shadow_outline_size", 3)
	_main_button("开始游戏", Rect2(641, 514, 390, 69), resume_game)
	var resume := _main_button("读取存档", Rect2(641, 601, 390, 69), resume_game)
	resume.disabled = not has_progress
	_main_button("退出游戏", Rect2(641, 688, 390, 69), func(): get_tree().quit())
	var settings := _level_button(canvas, "设置", Rect2(1538, 42, 64, 64), show_settings, false)
	settings.tooltip_text = "设置"
	for state in ["normal", "hover", "pressed"]:
		var style := StyleBoxTexture.new()
		style.texture = MainSettings
		style.modulate_color = Color("b9e5ff") if state == "hover" else (Color("88afca") if state == "pressed" else Color.WHITE)
		settings.add_theme_stylebox_override(state, style)
	for color_name in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		settings.add_theme_color_override(color_name, Color.TRANSPARENT)
	if not has_progress:
		var notice := _text(canvas, "暂无存档", Rect2(641, 768, 390, 30), 17, Color("e4edf4"))
		notice.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

func _main_button(value: String, rect: Rect2, action: Callable) -> Button:
	var button := Button.new()
	button.text = value; button.position = rect.position; button.size = rect.size
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_font_size_override("font_size", 29)
	button.add_theme_color_override("font_color", Color("edf3f9"))
	button.add_theme_color_override("font_hover_color", Color("203c60"))
	button.add_theme_color_override("font_pressed_color", Color("203c60"))
	button.add_theme_color_override("font_disabled_color", Color("a3afbe"))
	for state in ["normal", "hover", "pressed", "disabled"]:
		var style := StyleBoxTexture.new()
		style.texture = MainButtonLight if state in ["hover", "pressed"] else MainButtonDark
		style.modulate_color = Color(1, 1, 1, 0.65) if state == "disabled" else Color.WHITE
		button.add_theme_stylebox_override(state, style)
	var focus := StyleBoxFlat.new()
	focus.bg_color = Color.TRANSPARENT; focus.border_color = Color("fff1c9")
	focus.set_border_width_all(2)
	button.add_theme_stylebox_override("focus", focus)
	button.pressed.connect(func(): _play_ui("sfx_ui_click"))
	button.pressed.connect(action)
	canvas.add_child(button)
	return button

func show_settings() -> void:
	_menu_page("settings", 0.67)
	_play_music("music_main")
	_button(canvas, "‹", Rect2(30, 28, 90, 62), show_main)
	_text(canvas, "设置", Rect2(145, 27, 820, 75), 42)
	_line(Vector2(50, 187), Vector2(1520, 187))
	_slider_row("背景音乐", 300, audio_settings.music_volume, _set_music_volume)
	_slider_row("音效", 430, audio_settings.sfx_volume, _set_sfx_volume)
	_button(canvas, "返回", Rect2(85, 640, 450, 78), show_main)

func _slider_row(label: String, y: float, value: float, setter: Callable) -> void:
	_text(canvas, label, Rect2(100, y, 300, 46), 28)
	var slider := HSlider.new()
	slider.min_value = 0.0; slider.max_value = 1.0; slider.step = 0.01
	slider.value = value
	slider.position = Vector2(400, y + 8); slider.size = Vector2(600, 32)
	slider.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	canvas.add_child(slider)
	var readout := _text(canvas, "%d%%" % roundi(value * 100.0), Rect2(1030, y, 120, 46), 26, Color("b9d9e4"))
	slider.value_changed.connect(func(changed: float):
		setter.call(changed)
		readout.text = "%d%%" % roundi(changed * 100.0))

func _set_music_volume(value: float) -> void:
	audio_settings.music_volume = value
	audio.apply_settings(audio_settings)
	audio_settings.save(audio_settings_path)

func _set_sfx_volume(value: float) -> void:
	audio_settings.sfx_volume = value
	audio.apply_settings(audio_settings)
	audio_settings.save(audio_settings_path)

func show_levels() -> void:
	_menu_page("levels", 0.72)
	_play_music("music_main")
	# A quiet chapter header keeps the route and selected-stage detail prominent.
	var back := _level_button(canvas, "‹", Rect2(52, 49, 60, 54), show_main, false)
	back.add_theme_font_size_override("font_size", 34)
	back.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_text(canvas, "CHAPTER 01  /  SHANGHAI", Rect2(139, 44, 650, 23), 16, Color("8bb6c4"))
	_text(canvas, "第一章  ·  上海", Rect2(136, 70, 670, 63), 39, Color("f5f3eb"))
	_text(canvas, "寻找失踪的小黄", Rect2(139, 137, 650, 35), 21, Color("abc4cc"))
	_level_fill(canvas, Rect2(52, 192, 968, 1), Color("49636a"))
	if catalog.levels.is_empty():
		var issues := _text(canvas, "内容配置错误\n" + "\n".join(catalog.errors), Rect2(90, 250, 1400, 450), 22)
		issues.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		return
	var ids: Array = catalog.levels.keys()
	_text(canvas, "行动路线", Rect2(58, 213, 400, 42), 24, Color("e7edea"))
	_text(canvas, "%02d  /  %02d  已完成" % [progress.completed.size(), ids.size()], Rect2(755, 216, 260, 35), 17, Color("8aa8ad")).horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	for i in ids.size():
		var id: String = ids[i]
		if not progress.unlocked(id, ids): continue
		var x := 58.0 + (i % 3) * 320.0
		var y := 270.0 + int(i / 3) * 160.0
		_level_card(id, Rect2(x, y, 300, 138))
	if completed:
		_text(canvas, "章节完成  ·  信号已锁定", Rect2(60, 781, 820, 42), 20, Color("dec995"))
	else:
		_text(canvas, "选择已解锁的关卡，继续追寻小黄。", Rect2(60, 781, 820, 42), 20, Color("91aaae"))
	var level: Dictionary = catalog.levels[progress.selected]
	var detail := _level_panel(canvas, Rect2(1060, 52, 560, 837), Color("0a1c27ed"), Color("627f85"))
	_text(detail, "当前关卡", Rect2(28, 19, 250, 30), 18, Color("a9c9ce"))
	var type_label := "剧情" if level.type == "story" else "战斗"
	var type_color := Color("e4c88d") if level.type == "story" else Color("8ad9df")
	var badge := _level_panel(detail, Rect2(423, 18, 106, 31), Color("1c3941"), Color("49676a"))
	_text(badge, type_label, Rect2(0, 0, 106, 31), 16, type_color).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_level_fill(detail, Rect2(28, 61, 504, 1), Color("415e62"))
	if level.type == "battle": _add_preview(detail)
	else: _add_story_preview(detail, level)
	var code: String = str(level.name).get_slice(" ", 0)
	var title: String = str(level.name).trim_prefix(code).strip_edges()
	_text(detail, code, Rect2(30, 341, 500, 34), 21, type_color)
	var title_label := _text(detail, title, Rect2(30, 382, 500, 60), 33, Color("f4f2e8"))
	title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var description_text: String = level.description if level.type == "battle" or level.description != "剧情" else "阅读剧情，推进章节故事。"
	var description := _text(detail, description_text, Rect2(30, 453, 500, 82), 20, Color("abc2c4"))
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_level_fill(detail, Rect2(30, 551, 500, 1), Color("334f54"))
	if level.type == "battle":
		_text(detail, "出战干员", Rect2(30, 566, 450, 27), 17, Color("9eb8bc"))
		var roster: Array = catalog.battle_operator_ids(progress.selected, progress.available_operators())
		for i in mini(roster.size(), 5):
			var appearance = catalog.appearances(progress.selected, roster)[roster[i]]
			_image(detail, Rect2(30 + i * 95, 600, 75, 67), appearance.portrait)
			_text(detail, catalog.characters[roster[i]].stats.name, Rect2(25 + i * 95, 670, 85, 25), 15, Color("c8d5d2")).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	else:
		_text(detail, "剧情回顾" if progress.completed.has(progress.selected) else "故事即将展开", Rect2(30, 580, 480, 32), 19, Color("d0d9d2"))
		_text(detail, "已完成" if progress.completed.has(progress.selected) else "完成后继续前往下一关", Rect2(30, 620, 480, 28), 16, Color("8ba9aa"))
	var action := _level_button(detail, "开始行动   ›", Rect2(30, 737, 500, 66), begin_action, true)
	action.name = "StartAction"
	var issues: PackedStringArray = catalog.diagnostics(progress.selected)
	action.disabled = not issues.is_empty()
	if not issues.is_empty():
		var error_label := _text(canvas, "\n".join(issues), Rect2(58, 825, 960, 90), 16, Color("ffbd9b"))
		error_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if not save_notice.is_empty(): _text(canvas, save_notice, Rect2(670, 856, 350, 28), 18, Color("ffbd9b"))

func _level_style(color: Color, border: Color, radius := 7) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(radius)
	return style

func _level_panel(parent: Control, rect: Rect2, color: Color, border: Color) -> Panel:
	var panel := Panel.new()
	panel.position = rect.position; panel.size = rect.size
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", _level_style(color, border))
	parent.add_child(panel)
	return panel

func _level_fill(parent: Control, rect: Rect2, color: Color) -> void:
	var fill := ColorRect.new()
	fill.position = rect.position; fill.size = rect.size; fill.color = color
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(fill)

func _level_button(parent: Control, label: String, rect: Rect2, action: Callable, primary: bool) -> Button:
	var button := Button.new()
	button.text = label; button.position = rect.position; button.size = rect.size
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_font_size_override("font_size", 25 if primary else 20)
	button.add_theme_color_override("font_color", Color("122f32") if primary else Color("e7f2ef"))
	button.add_theme_color_override("font_disabled_color", Color("758988"))
	button.add_theme_stylebox_override("normal", _level_style(Color("a4dbd1") if primary else Color("122d37dd"), Color("c4f1e5") if primary else Color("72959b")))
	button.add_theme_stylebox_override("hover", _level_style(Color("c2eee0") if primary else Color("234854"), Color("c4f1e5")))
	button.add_theme_stylebox_override("pressed", _level_style(Color("79beb5") if primary else Color("1a3a42"), Color("a6d9d3")))
	button.add_theme_stylebox_override("disabled", _level_style(Color("354d4d"), Color("516a69")))
	var focus := _level_style(Color(0, 0, 0, 0), Color("e6d39c")); focus.set_border_width_all(2)
	button.add_theme_stylebox_override("focus", focus)
	button.pressed.connect(func(): _play_ui("sfx_ui_click"))
	button.pressed.connect(action)
	parent.add_child(button)
	return button

func _level_card(id: String, rect: Rect2) -> void:
	var level: Dictionary = catalog.levels[id]
	var selected: bool = id == progress.selected
	var done: bool = progress.completed.has(id)
	var story: bool = level.type == "story"
	var accent := Color("e6c88b") if story else Color("83d7d7")
	var button := _level_button(canvas, "", rect, _select_level.bind(id), false)
	button.tooltip_text = level.name
	button.add_theme_stylebox_override("normal", _level_style(Color("173a43ee") if selected else Color("0b1e28e8"), accent if selected else Color("39555a")))
	button.add_theme_stylebox_override("hover", _level_style(Color("214954"), accent))
	button.add_theme_stylebox_override("pressed", _level_style(Color("193d46"), accent))
	_level_fill(button, Rect2(0, 18, 4, 102), accent if selected else Color("52777a"))
	var code: String = str(level.name).get_slice(" ", 0)
	var title: String = str(level.name).trim_prefix(code).strip_edges()
	_text(button, code, Rect2(19, 13, 140, 32), 22, Color("e9f0e9"))
	var status := _text(button, "已完成" if done else "可行动", Rect2(187, 17, 93, 25), 15, Color("a5c3bc") if done else accent)
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	var title_label := _text(button, title, Rect2(19, 50, 260, 47), 19, Color("d9e6e1"))
	title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_level_fill(button, Rect2(19, 105, 260, 1), Color("36545a"))
	_text(button, "剧情  /  STORY" if story else "战斗  /  BATTLE", Rect2(19, 110, 240, 20), 14, accent)

func _add_story_preview(parent: Control, level: Dictionary) -> void:
	var frame := _level_panel(parent, Rect2(24, 76, 512, 242), Color("142b31"), Color("54777b"))
	frame.clip_contents = true
	var script = catalog.story(level.story)
	var opening: Dictionary = script.nodes.get(script.start, {})
	var texture_path: String = catalog.backgrounds.get(opening.get("background", ""), "")
	if not texture_path.is_empty():
		var image := _image(frame, Rect2(0, 0, 512, 242), load(texture_path))
		image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_level_fill(frame, Rect2(0, 190, 512, 52), Color(0.02, 0.06, 0.07, 0.72))
	_text(frame, "上海  /  剧情记录", Rect2(17, 199, 430, 28), 16, Color("e6e2cc"))

func _select_level(id: String) -> void:
	if not progress.unlocked(id, catalog.levels.keys()): return
	progress.selected = id
	show_levels()

func begin_action() -> void:
	if not progress.pending_after.is_empty():
		_continue_campaign(); return
	if not progress.unlocked(progress.selected, catalog.levels.keys()): return
	if not catalog.diagnostics(progress.selected).is_empty(): return
	progress.started = true
	_save_progress()
	if catalog.levels[progress.selected].type == "story": show_story(progress.selected, "story")
	else: start_battle()

func show_story(id: String, kind: String) -> void:
	if not catalog.diagnostics(id).is_empty(): show_levels(); return
	_clear_page()
	page = "story"
	_play_music("music_main")
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
	story_view.ui_sound_requested.connect(_play_ui)
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
		button.pressed.connect(func(): _play_ui("sfx_ui_click"))
		button.pressed.connect(entry[1]); toolbar.add_child(button)

func advance_story() -> void:
	if page != "story": return
	if session.advance():
		if session.snapshot().finished: finish_story()
		else: story_view.show_snapshot(session.snapshot())

func finish_story() -> void:
	if page != "story": return
	if progress.completed.has(story_level):
		show_levels()
		return
	progress.pending_after = story_level
	progress.finish_story(catalog.levels.keys(), catalog.recruits, catalog.departures, catalog.returns)
	_save_progress()
	if progress.selected != story_level and catalog.levels[progress.selected].type == "battle": start_battle()
	else: show_levels()

func _focus_action() -> void:
	canvas.find_child("StartAction", true, false).grab_focus()

func _add_preview(parent: Control) -> void:
	_level_panel(parent, Rect2(24, 76, 512, 242), Color("142b31"), Color("54777b"))
	var container := SubViewportContainer.new()
	container.position = Vector2(25, 76); container.size = Vector2(510, 242)
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
	_level_fill(parent, Rect2(25, 76, 510, 242), Color(0.02, 0.10, 0.12, 0.35))

func start_battle() -> void:
	if not progress.unlocked(progress.selected, catalog.levels.keys()): return
	if not catalog.diagnostics(progress.selected).is_empty(): return
	progress.started = true
	_save_progress()
	_clear_page()
	page = "battle"
	_play_music("music_battle")
	result_recorded = false
	battle_scene = BattleScene.instantiate()
	battle_scene.audio = audio
	battle_scene.campaign_level = progress.selected
	battle_scene.operator_ids.assign(progress.available_operators())
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
	if progress.selected == "scene_0101B" and not tutorial_seen: _show_tutorial()

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
	if battle_scene and battle_scene.last_state.phase == "victory": _continue_campaign()
	else: show_levels()

func _continue_campaign() -> void:
	var id: String = progress.pending_after
	if id.is_empty(): show_levels(); return
	if not catalog.diagnostics(id).is_empty(): show_levels(); return
	progress.finish_story(catalog.levels.keys(), catalog.recruits, catalog.departures, catalog.returns)
	_save_progress()
	if progress.selected != id and catalog.levels[progress.selected].type == "story": show_story(progress.selected, "story")
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
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE and page in ["levels", "settings"]:
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
	button.pressed.connect(func(): _play_ui("sfx_ui_click"))
	button.pressed.connect(action)
	parent.add_child(button)
	return button

func _line(a: Vector2, b: Vector2) -> void:
	var line := Line2D.new()
	line.points = PackedVector2Array([a, b]); line.width = 1
	line.default_color = Color("668392")
	canvas.add_child(line)
