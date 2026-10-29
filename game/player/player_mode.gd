extends Control
## Product flow owns navigation and progress; the shared battle owns gameplay.
const BattleScene = preload("res://game/battle/battle_scene.tscn")
const Background = preload("res://content/ui/player/background.png")
const Atlas = preload("res://content/ui/player/atlas.png")
const MainBackground = preload("res://content/ui/player/main_background_v2.png")
const LevelsBackground = preload("res://content/ui/player/levels_background_v1.png")
const MainEmblem = preload("res://content/ui/player/main_emblem_v2.png")
const MainButtonLight = preload("res://content/ui/player/main_button_light_v2.png")
const MainButtonDark = preload("res://content/ui/player/main_button_dark_v2.png")
const MainSettings = preload("res://content/ui/player/main_settings_v2.png")
const FirstBattleHintImage = preload("res://content/ui/tutorial/scene_0101B_battle.png")
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
@export var developer_mode := false
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
var selected_squad: Array[String] = []
var squad_level := ""

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	developer_mode = developer_mode or "--developer-mode" in OS.get_cmdline_user_args()
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
	progress = Progress.new()
	if not developer_mode:
		progress.load_progress(save_path, catalog.levels.keys())
	elif not catalog.levels.is_empty():
		progress.selected = str(catalog.levels.keys()[0])
	progress.configure_operators(catalog.starting_operators, catalog.recruits, catalog.characters.keys(), catalog.departures, catalog.returns)
	has_progress = progress.started or not progress.pending_after.is_empty()
	completed = progress.completed.size() == catalog.levels.size() and not catalog.levels.is_empty()

func _save_progress() -> void:
	var result: Error = OK if developer_mode else progress.save(save_path)
	save_notice = "" if result == OK else "进度未能保存"
	has_progress = progress.started
	completed = progress.completed.size() == catalog.levels.size() and not catalog.levels.is_empty()

func resume_game() -> void:
	if not developer_mode: _load_progress()
	if not progress.pending_after.is_empty(): _continue_campaign()
	else: show_levels()

func new_game() -> void:
	progress = Progress.new()
	selected_squad.clear(); squad_level = ""
	if not catalog.levels.is_empty(): progress.selected = str(catalog.levels.keys()[0])
	progress.configure_operators(catalog.starting_operators, catalog.recruits, catalog.characters.keys(), catalog.departures, catalog.returns)
	completed = false
	save_notice = ""
	show_levels()

func _level_unlocked(id: String) -> bool:
	var ids: Array = catalog.levels.keys()
	return ids.has(id) and (developer_mode or progress.unlocked(id, ids))

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
	background.texture = MainBackground if kind == "main" else (LevelsBackground if kind == "levels" else Background)
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
	_main_button("开始游戏", Rect2(641, 514, 390, 69), new_game)
	var resume := _main_button("读取存档", Rect2(641, 601, 390, 69), resume_game)
	resume.disabled = not has_progress
	if developer_mode: _text(canvas, "开发者模式", Rect2(48, 42, 250, 35), 19, Color("ffe2a0"))
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

func show_levels(preserve_scroll := -1) -> void:
	_menu_page("levels", 0.28)
	_play_music("music_main")
	var back := _level_button(canvas, "‹", Rect2(48, 50, 60, 58), show_main, false)
	back.add_theme_font_size_override("font_size", 36)
	back.add_theme_stylebox_override("normal", _level_style(Color("15263ee8"), Color("60799e")))
	back.add_theme_stylebox_override("hover", _level_style(Color("2a4161"), Color("ffe1a1")))
	_image(canvas, Rect2(130, 30, 95, 100), MainEmblem)
	_text(canvas, "星世界", Rect2(226, 47, 220, 50), 33, Color("f4f3f4"))
	_text(canvas, "S T A R  W O R L D", Rect2(228, 94, 250, 22), 13, Color("9cb4d6"))
	if catalog.levels.is_empty():
		var errors := _text(canvas, "内容配置错误\n" + "\n".join(catalog.errors), Rect2(90, 250, 1400, 450), 22)
		errors.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		return
	var ids: Array = catalog.levels.keys()
	var chapter := _level_panel(canvas, Rect2(48, 174, 355, 106), Color("152b48f2"), Color("ffe1a1"))
	_level_fill(chapter, Rect2(0, 0, 6, 106), Color("ffe2a0"))
	_text(chapter, "01", Rect2(25, 12, 100, 31), 20, Color("ffe2a0"))
	_text(chapter, "第一章 · 上海", Rect2(25, 45, 300, 45), 27, Color("fff1d0"))
	var locked_chapter := _level_panel(canvas, Rect2(48, 296, 355, 85), Color("12243ddd"), Color("49617f"))
	locked_chapter.name = "LockedChapter"
	_text(locked_chapter, "锁定", Rect2(27, 20, 260, 45), 22, Color("8399bb"))
	_lock_icon(locked_chapter, Vector2(305, 27))
	var route := _level_panel(canvas, Rect2(432, 161, 542, 730), Color("101f36e8"), Color("536a89"))
	_text(route, "第一章 · 上海", Rect2(32, 22, 360, 45), 30, Color("f7f4ef"))
	_level_fill(route, Rect2(32, 110, 478, 1), Color("52657d"))
	var scroll := ScrollContainer.new()
	scroll.name = "LevelScroll"
	scroll.position = Vector2(28, 125); scroll.size = Vector2(486, 580)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	route.add_child(scroll)
	var list := VBoxContainer.new()
	list.name = "LevelList"
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 10)
	scroll.add_child(list)
	var selected_button: Control
	var has_locked := false
	for id in ids:
		if not _level_unlocked(id):
			has_locked = true
			break
		var card := _route_card(list, id)
		if id == progress.selected: selected_button = card
	if has_locked:
		var locked := _level_panel(list, Rect2(0, 0, 0, 76), Color("101e32c9"), Color("394e6a"))
		locked.name = "LockedLevel"
		locked.custom_minimum_size = Vector2(0, 76)
		_lock_icon(locked, Vector2(25, 21))
		_text(locked, "锁定", Rect2(195, 19, 100, 38), 20, Color("8399bb"))
	if preserve_scroll >= 0:
		_restore_level_scroll.call_deferred(scroll, preserve_scroll)
	elif selected_button:
		_reveal_level.call_deferred(scroll, selected_button)
	_level_detail(catalog.levels[progress.selected])
	var issues: PackedStringArray = catalog.diagnostics(progress.selected)
	if not issues.is_empty():
		var error_scroll := ScrollContainer.new()
		error_scroll.name = "LevelDiagnostics"
		error_scroll.position = Vector2(435, 810); error_scroll.size = Vector2(1100, 120)
		error_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		canvas.add_child(error_scroll)
		var error_label := _detail_label("\n".join(issues), 15, Color("ffbd9b"))
		error_label.custom_minimum_size.x = 1080
		error_scroll.add_child(error_label)
	if not save_notice.is_empty(): _text(canvas, save_notice, Rect2(48, 850, 350, 30), 18, Color("ffbd9b"))

func _lock_icon(parent: Control, pos: Vector2) -> void:
	var shackle := Line2D.new()
	shackle.points = PackedVector2Array([pos + Vector2(6, 14), pos + Vector2(6, 8), pos + Vector2(9, 3), pos + Vector2(15, 1), pos + Vector2(21, 3), pos + Vector2(24, 8), pos + Vector2(24, 14)])
	shackle.width = 3
	shackle.default_color = Color("8399bb")
	parent.add_child(shackle)
	_level_fill(parent, Rect2(pos + Vector2(3, 13), Vector2(24, 18)), Color("8399bb"))
	_level_fill(parent, Rect2(pos + Vector2(14, 19), Vector2(3, 7)), Color("15263e"))

func _reveal_level(scroll: ScrollContainer, selected: Control) -> void:
	await get_tree().process_frame
	if is_instance_valid(scroll) and is_instance_valid(selected): scroll.ensure_control_visible(selected)

func _restore_level_scroll(scroll: ScrollContainer, position: int) -> void:
	await get_tree().process_frame
	if is_instance_valid(scroll): scroll.scroll_vertical = position

func _detail_label(value: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size.x = 480
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label

func _level_detail(level: Dictionary) -> void:
	var scroll := ScrollContainer.new()
	scroll.name = "DetailScroll"
	scroll.position = Vector2(998, 161); scroll.size = Vector2(626, 730)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	canvas.add_child(scroll)
	var center := CenterContainer.new()
	center.custom_minimum_size = Vector2(606, 730)
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(center)
	var panel := PanelContainer.new()
	panel.name = "LevelDetail"
	panel.custom_minimum_size.x = 570
	panel.add_theme_stylebox_override("panel", _level_style(Color("15263eef"), Color("61738e")))
	center.add_child(panel)
	var margin := MarginContainer.new()
	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]: margin.add_theme_constant_override(side, 36)
	panel.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 24)
	margin.add_child(column)
	var heading := HBoxContainer.new()
	heading.add_theme_constant_override("separation", 16)
	column.add_child(heading)
	var title := _detail_label(str(level.name), 33, Color("f8f5ef"))
	title.name = "DetailTitle"
	title.custom_minimum_size.x = 0
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_child(title)
	var badge := PanelContainer.new()
	badge.name = "LevelTypeBadge"
	badge.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	var is_story: bool = level.type == "story"
	badge.add_theme_stylebox_override("panel", _level_style(Color("29354a") if is_story else Color("1c354b"), Color("ad986e") if is_story else Color("648eb1")))
	heading.add_child(badge)
	var badge_margin := MarginContainer.new()
	for side in ["margin_left", "margin_right"]: badge_margin.add_theme_constant_override(side, 12)
	for side in ["margin_top", "margin_bottom"]: badge_margin.add_theme_constant_override(side, 5)
	badge.add_child(badge_margin)
	var badge_label := Label.new()
	badge_label.name = "LevelType"
	badge_label.text = "剧情" if is_story else "战斗"
	badge_label.add_theme_font_size_override("font_size", 17)
	badge_label.add_theme_color_override("font_color", Color("f1d79d") if is_story else Color("b6dcf5"))
	badge_margin.add_child(badge_label)
	var separator := ColorRect.new()
	separator.color = Color("67758a"); separator.custom_minimum_size.y = 1
	column.add_child(separator)
	if not is_story and level.roster_mode == "player":
		if squad_level != level.id:
			squad_level = level.id
			selected_squad.assign(progress.available_operators())
		else:
			selected_squad.assign(selected_squad.filter(func(id): return progress.available_operators().has(id)))
		var squad_title := _detail_label("选择出战干员", 20, Color("d1dbe8"))
		column.add_child(squad_title)
		for id in progress.available_operators():
			var choice := CheckBox.new()
			choice.name = "Squad_" + id
			choice.text = str(catalog.characters[id].stats.name)
			choice.button_pressed = selected_squad.has(id)
			choice.toggled.connect(func(enabled: bool):
				if enabled and not selected_squad.has(id): selected_squad.append(id)
				elif not enabled: selected_squad.erase(id)
				var start := column.get_node_or_null("StartAction") as Button
				if start: start.disabled = selected_squad.is_empty())
			column.add_child(choice)
	var action := _level_button(column, "进入故事" if is_story else "开始战斗", Rect2(0, 0, 0, 66), begin_action, true)
	action.name = "StartAction"
	action.custom_minimum_size.y = 66
	action.add_theme_color_override("font_color", Color("14243a"))
	action.add_theme_color_override("font_hover_color", Color("14243a"))
	action.add_theme_stylebox_override("normal", _level_style(Color("ffe8b5"), Color("ffeac3")))
	action.add_theme_stylebox_override("hover", _level_style(Color("fff3d4"), Color("fff7e4")))
	action.add_theme_stylebox_override("pressed", _level_style(Color("e9c986"), Color("ffeac3")))
	action.disabled = not catalog.diagnostics(progress.selected).is_empty()
	if not is_story and level.roster_mode == "player" and selected_squad.is_empty(): action.disabled = true

func _route_card(parent: Control, id: String) -> Button:
	var level: Dictionary = catalog.levels[id]
	var selected: bool = id == progress.selected
	var done: bool = progress.completed.has(id)
	var accent := Color("ffe2a0") if selected else Color("6d89b1")
	var button := _level_button(parent, "", Rect2(0, 0, 0, 76), _select_level.bind(id), false)
	button.name = "Level_" + id
	button.custom_minimum_size = Vector2(0, 76)
	button.tooltip_text = level.name
	button.add_theme_stylebox_override("normal", _level_style(Color("172b46f4") if selected else Color("101f35e8"), accent if selected else Color("405673")))
	button.add_theme_stylebox_override("hover", _level_style(Color("263e5b"), Color("ffe2a0")))
	button.add_theme_stylebox_override("pressed", _level_style(Color("1b304c"), Color("ffe2a0")))
	_level_fill(button, Rect2(0, 10, 4, 56), accent)
	_text(button, "✦", Rect2(20, 16, 44, 44), 25, Color("99c4ed"))
	var code: String = str(level.name).get_slice(" ", 0)
	var title: String = str(level.name).trim_prefix(code).strip_edges()
	_text(button, code, Rect2(73, 19, 95, 38), 21, Color("f1f3f6"))
	var title_label := _text(button, title, Rect2(169, 10, 155, 56), 20, Color("e9edf4"))
	title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var is_story: bool = level.type == "story"
	var badge := _level_panel(button, Rect2(332, 21, 64, 34), Color("29354a") if is_story else Color("1c354b"), Color("ad986e") if is_story else Color("648eb1"))
	badge.name = "RouteTypeBadge"
	var type_label := _text(badge, "剧情" if is_story else "战斗", Rect2(0, 0, 64, 34), 16, Color("f1d79d") if is_story else Color("b6dcf5"))
	type_label.name = "RouteType"
	type_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if done:
		var status := _text(button, "已完成", Rect2(400, 19, 58, 38), 16, Color("a7bad4"))
		status.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	return button

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

func _select_level(id: String) -> void:
	if not _level_unlocked(id): return
	var scroll := find_child("LevelScroll", true, false) as ScrollContainer
	var scroll_position := scroll.scroll_vertical if scroll else -1
	progress.selected = id
	show_levels(scroll_position)

func begin_action() -> void:
	if not progress.pending_after.is_empty():
		_continue_campaign(); return
	if not _level_unlocked(progress.selected): return
	if not catalog.diagnostics(progress.selected).is_empty(): return
	if catalog.levels[progress.selected].get("roster_mode", "") == "player" and (squad_level != progress.selected or selected_squad.is_empty()): return
	progress.started = true
	_save_progress()
	if catalog.levels[progress.selected].type == "story": show_story(progress.selected, "story")
	else: start_battle()

func show_story(id: String, kind: String) -> void:
	if not catalog.diagnostics(id).is_empty(): show_levels(); return
	_clear_page()
	page = "story"
	_play_music(catalog.levels[id].music if not catalog.levels[id].music.is_empty() else "music_main")
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
	if story_view.reveal_dialogue(): return
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
	if progress.selected != story_level and catalog.levels[progress.selected].type == "battle" and catalog.levels[progress.selected].roster_mode == "fixed": start_battle()
	else: show_levels()

func _focus_action() -> void:
	canvas.find_child("StartAction", true, false).grab_focus()

func start_battle() -> void:
	if not _level_unlocked(progress.selected): return
	if not catalog.diagnostics(progress.selected).is_empty(): return
	if catalog.levels[progress.selected].roster_mode == "player":
		selected_squad.assign(selected_squad.filter(func(id): return progress.available_operators().has(id)))
		if squad_level != progress.selected or selected_squad.is_empty(): show_levels(); return
	progress.started = true
	_save_progress()
	_clear_page()
	page = "battle"
	_play_music("music_battle")
	result_recorded = false
	battle_scene = BattleScene.instantiate()
	battle_scene.developer_tools_enabled = developer_mode
	battle_scene.audio = audio
	battle_scene.campaign_level = progress.selected
	if catalog.levels[progress.selected].roster_mode == "player" and squad_level == progress.selected:
		battle_scene.operator_ids.assign(selected_squad)
	else: battle_scene.operator_ids.assign(progress.available_operators())
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
	battle_scene.hud.style_battle_button(return_button)
	return_button.custom_minimum_size = Vector2(220, 48)
	return_button.add_theme_font_size_override("font_size", 22)
	return_button.pressed.connect(_leave_result)
	battle_scene.hud.end_panel.get_child(0).add_child(return_button)
	if progress.selected == "scene_0101B" and not tutorial_seen: _show_tutorial()

func _show_tutorial() -> void:
	tutorial_seen = true
	battle_scene.battle.set_paused(true)
	battle_scene.refresh()
	var shade := ColorRect.new()
	shade.color = Color(0.0, 0.0, 0.0, 0.72)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	shade.z_index = 100
	battle_scene.hud.add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_STOP
	shade.add_child(center)
	tutorial = PanelContainer.new()
	tutorial.custom_minimum_size.x = 600
	tutorial.mouse_filter = Control.MOUSE_FILTER_STOP
	var style: StyleBox = battle_scene.hud.battle_panel_style()
	style.content_margin_left = 18; style.content_margin_right = 18
	style.content_margin_top = 14; style.content_margin_bottom = 14
	tutorial.add_theme_stylebox_override("panel", style)
	var column := VBoxContainer.new(); tutorial.add_child(column)
	column.add_theme_constant_override("separation", 10)
	var title := Label.new(); title.text = "关卡提示"
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color("b5dfed"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title)
	var screenshot := TextureRect.new()
	screenshot.texture = FirstBattleHintImage
	screenshot.custom_minimum_size = Vector2(564, 250)
	screenshot.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	screenshot.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	screenshot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(screenshot)
	var label := Label.new()
	label.text = "按住角色卡拖到战场，松开后选择朝向进行部署。\n角色会阻挡并攻击敌人；阻止敌人进入蓝色基地。\n部署消耗费用，费用会随时间恢复。"
	label.add_theme_font_size_override("font_size", 18)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(label)
	var close := Button.new(); close.text = "确认"
	battle_scene.hud.style_battle_button(close)
	close.custom_minimum_size.y = 42
	close.pressed.connect(func():
		tutorial = null
		shade.queue_free()
		battle_scene.battle.set_paused(false)
		battle_scene.refresh())
	column.add_child(close)
	center.add_child(tutorial)

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
	if is_instance_valid(tutorial) and state.phase in ["victory", "defeat"]:
		tutorial.get_parent().get_parent().queue_free()
		tutorial = null

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
