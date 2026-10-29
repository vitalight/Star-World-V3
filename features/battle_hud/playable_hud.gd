extends "res://features/battle_hud/battle_hud_overlay.gd"
## Interactive variant sharing the Art Test HUD's styles and playback intents.
class RangePreview extends Control:
	var cells: Array = []
	func _draw() -> void:
		if cells.is_empty(): return
		var low := Vector2i.ZERO
		var high := Vector2i.ZERO
		for cell in cells:
			low = Vector2i(mini(low.x, cell.x), mini(low.y, cell.y))
			high = Vector2i(maxi(high.x, cell.x), maxi(high.y, cell.y))
		var count := high - low + Vector2i.ONE
		var step := minf(size.x / count.x, size.y / count.y)
		var origin := (size - Vector2(count) * step) / 2.0
		for cell in cells:
			var rect := Rect2(origin + Vector2(cell - low) * step, Vector2.ONE * (step - 1.0))
			draw_rect(rect, Color("f5e0bd") if cell == Vector2i.ZERO else Color("a75516"))
			draw_rect(rect, Color("ff9b36"), false, 1.0)

signal roster_selected(roster_id: String)
signal roster_drag_started(roster_id: String)
signal roster_drag_ended
signal roster_drag_hovered(point: Vector2)
signal roster_dropped(roster_id: String, point: Vector2)
signal cancel_requested
signal retreat_requested
signal skill_requested
signal menu_requested
signal debug_victory_requested
signal continue_requested
signal ui_sound_requested(id: String)
var developer_tools_enabled := false
var replay_mode := false
## Optional nine-slice panel art supplied by the game composition layer.
var panel_texture: Texture2D
var dragged_roster := ""
var pressed_roster := ""
var suppress_card_click := false
var drag_origin := Vector2.ZERO
var drag_preview: Control
var drop_hit_test: Callable
var readouts: VBoxContainer
var cards := {}
var status: Label
var life_status: Label
var leak_warning: Label
var notice: Label
var selection: Label
var retreat_button: Button
var skill_button: Button
var skill_status: Label
var normal_skill_style: StyleBox
var ready_skill_style: StyleBoxFlat
var deployment_cancel_button: Button
var deployment_anchor := Vector2.ZERO
var end_panel: PanelContainer
var end_label: Label
var result_button: Button
var result_victory := false
var roster: Dictionary
var catalog: Dictionary
var skill_icons: Dictionary = {}
var selected_roster := ""
var selected_unit := -1
var info_panel: PanelContainer
var top: HBoxContainer
var bottom: HBoxContainer
var economy: Label
var deployment_count: Label
var operator_portrait: TextureRect
var skill_portrait: TextureRect
var skill_description: Label
var range_preview: RangePreview
var operator_class_icon: TextureRect
var operator_name: Label
var operator_anchor := Vector2.ZERO
var game_menu: PanelContainer
var developer_panel: PanelContainer
var debug_victory_button: Button
var objective_label: Label

func _draw() -> void:
	# The interactive layout replaces the fixed Art Test readout rectangles.
	pass

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_PASS
	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shader := ShaderMaterial.new()
	shader.shader = preload("res://features/battle_hud/vignette.gdshader")
	shade.material = shader
	add_child(shade)
	top = HBoxContainer.new()
	top.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	top.offset_left = 18; top.offset_right = -18; top.offset_top = 16
	top.add_theme_constant_override("separation", 10)
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(top)
	var menu_button := _button(top, "☰", func(): game_menu.visible = not game_menu.visible)
	menu_button.accessibility_name = "战斗菜单"
	if replay_mode:
		var replay_label := _label(top, "回放中", 20)
		replay_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(spacer)
	speed_button = _button(top, "1×", func(): speed_requested.emit())
	pause_button = _button(top, "", func(): pause_requested.emit())
	for button in [menu_button, speed_button, pause_button]:
		button.custom_minimum_size = Vector2(93, 63)
		button.add_theme_font_size_override("font_size", 29)
	var progress := _panel_container()
	progress.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	progress.offset_left = -210; progress.offset_right = 210
	progress.offset_top = 10; progress.offset_bottom = 78
	progress.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var progress_row := HBoxContainer.new()
	progress_row.add_theme_constant_override("separation", 0)
	progress.add_child(progress_row)
	var enemy_group := HBoxContainer.new()
	enemy_group.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	enemy_group.alignment = BoxContainer.ALIGNMENT_CENTER
	enemy_group.add_theme_constant_override("separation", 10)
	progress_row.add_child(enemy_group)
	_status_icon(enemy_group, preload("res://features/battle_hud/enemy_progress.svg"))
	var enemy_readout := VBoxContainer.new()
	enemy_readout.add_theme_constant_override("separation", -4)
	enemy_group.add_child(enemy_readout)
	status = _label(enemy_readout, "0 / 0", 22)
	var enemy_caption := _label(enemy_readout, "敌人数量", 14)
	enemy_caption.add_theme_color_override("font_color", Color("aac1c9"))
	var divider := ColorRect.new()
	divider.color = Color("6b8991")
	divider.custom_minimum_size = Vector2(1, 34)
	divider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	progress_row.add_child(divider)
	var life_group := HBoxContainer.new()
	life_group.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	life_group.alignment = BoxContainer.ALIGNMENT_CENTER
	life_group.add_theme_constant_override("separation", 10)
	progress_row.add_child(life_group)
	_status_icon(life_group, preload("res://features/battle_hud/base_life.svg"))
	var life_readout := VBoxContainer.new()
	life_readout.add_theme_constant_override("separation", -4)
	life_group.add_child(life_readout)
	life_status = _label(life_readout, "0", 22)
	var life_caption := _label(life_readout, "基地生命", 14)
	life_caption.add_theme_color_override("font_color", Color("aac1c9"))
	leak_warning = Label.new()
	leak_warning.text = "敌人接近！"
	leak_warning.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	leak_warning.offset_left = -120; leak_warning.offset_right = 120
	leak_warning.offset_top = 108; leak_warning.offset_bottom = 140
	leak_warning.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	leak_warning.add_theme_font_size_override("font_size", 22)
	leak_warning.add_theme_color_override("font_color", Color("ffac83"))
	leak_warning.add_theme_color_override("font_shadow_color", Color("21100e"))
	leak_warning.add_theme_constant_override("shadow_offset_x", 2)
	leak_warning.add_theme_constant_override("shadow_offset_y", 2)
	leak_warning.mouse_filter = Control.MOUSE_FILTER_IGNORE
	leak_warning.hide()
	add_child(leak_warning)
	objective_label = Label.new()
	objective_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	objective_label.offset_left = -180; objective_label.offset_right = 180
	objective_label.offset_top = 82; objective_label.offset_bottom = 108
	objective_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	objective_label.add_theme_font_size_override("font_size", 19)
	objective_label.add_theme_color_override("font_color", Color("b5dfed"))
	objective_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(objective_label)
	readouts = VBoxContainer.new()
	readouts.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	readouts.offset_left = 80; readouts.offset_right = 347
	readouts.offset_top = -100; readouts.offset_bottom = -18
	readouts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(readouts)
	notice = _label(readouts, "", 16)
	notice.hide()
	notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var economy_panel := _panel_container()
	economy_panel.name = "Economy"
	economy_panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	economy_panel.offset_left = -205; economy_panel.offset_right = -18
	economy_panel.offset_top = -225; economy_panel.offset_bottom = -158
	economy_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var economy_rows := VBoxContainer.new()
	economy_rows.add_theme_constant_override("separation", 0)
	economy_panel.add_child(economy_rows)
	economy = _label(economy_rows, "", 44)
	economy.add_theme_color_override("font_color", Color("f6d38c"))
	economy.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	deployment_count = _label(economy_rows, "", 22)
	deployment_count.add_theme_color_override("font_color", Color("bed1d2"))
	deployment_count.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	bottom = HBoxContainer.new()
	bottom.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	bottom.offset_right = -18; bottom.offset_bottom = -14
	bottom.alignment = BoxContainer.ALIGNMENT_END
	bottom.add_theme_constant_override("separation", 5)
	bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bottom)
	for key in roster:
		var card := Button.new()
		card.custom_minimum_size = Vector2(100, 128)
		card.clip_contents = true
		card.accessibility_name = roster[key].name
		style_battle_button(card)
		card.pressed.connect(func():
			if suppress_card_click: return
			ui_sound_requested.emit("sfx_ui_click")
			roster_selected.emit(key))
		card.gui_input.connect(func(event): _card_input(key, event))
		bottom.add_child(card)
		var portrait := TextureRect.new()
		portrait.texture = catalog[key].portrait
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		portrait.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		portrait.offset_top = 27
		portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(portrait)
		var strip := ColorRect.new()
		strip.color = Color("10232df2")
		strip.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
		strip.offset_bottom = 27
		strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(strip)
		var value := _label(card, "%d" % roster[key].cost, 20)
		value.add_theme_color_override("font_color", Color("f6d38c"))
		value.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
		value.offset_left = 31; value.offset_right = 72
		value.offset_bottom = 27
		value.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		var class_icon := TextureRect.new()
		class_icon.texture = catalog[key].class_icon
		class_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		class_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		class_icon.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
		class_icon.offset_left = 2; class_icon.offset_right = 28
		class_icon.offset_top = 1; class_icon.offset_bottom = 27
		class_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(class_icon)
		var cooldown := ColorRect.new()
		cooldown.color = Color(0.08, 0.06, 0.08, 0.82)
		cooldown.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		cooldown.offset_top = 27
		cooldown.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(cooldown)
		var timer := _label(cooldown, "", 25)
		timer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		timer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		timer.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		cooldown.hide()
		cards[key] = {"button": card, "value": value, "cooldown": cooldown, "timer": timer, "portrait": portrait, "class_icon": class_icon}
	info_panel = _panel_container()
	info_panel.position.x = 18
	info_panel.resized.connect(_center_info_panel)
	info_panel.custom_minimum_size = Vector2(300, 0)
	var info := VBoxContainer.new()
	info.add_theme_constant_override("separation", 8)
	info_panel.add_child(info)
	operator_portrait = TextureRect.new()
	operator_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	operator_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	operator_portrait.custom_minimum_size = Vector2(200, 160)
	operator_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info.add_child(operator_portrait)
	var heading := HBoxContainer.new()
	heading.add_theme_constant_override("separation", 10)
	info.add_child(heading)
	operator_class_icon = TextureRect.new()
	operator_class_icon.custom_minimum_size = Vector2(48, 48)
	operator_class_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	operator_class_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	operator_class_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	heading.add_child(operator_class_icon)
	operator_name = _label(heading, "", 24)
	operator_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	operator_name.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var details := HBoxContainer.new()
	details.add_theme_constant_override("separation", 8)
	info.add_child(details)
	var details_text := VBoxContainer.new()
	details_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	details.add_child(details_text)
	selection = _label(details_text, "", 16)
	var range_column := VBoxContainer.new()
	range_column.size_flags_vertical = Control.SIZE_SHRINK_END
	details.add_child(range_column)
	range_preview = RangePreview.new()
	range_preview.custom_minimum_size = Vector2(76, 76)
	range_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	range_column.add_child(range_preview)
	var range_caption := _label(range_column, "攻击范围", 14)
	range_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var skill_info := HBoxContainer.new()
	skill_info.add_theme_constant_override("separation", 10)
	info.add_child(skill_info)
	skill_portrait = TextureRect.new()
	skill_portrait.custom_minimum_size = Vector2(48, 48)
	skill_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	skill_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	skill_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	skill_info.add_child(skill_portrait)
	skill_description = _label(skill_info, "", 15)
	skill_description.custom_minimum_size.x = 142
	skill_description.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	skill_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	skill_status = _label(info, "", 14)
	skill_status.add_theme_color_override("font_color", Color("f6d38c"))
	skill_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	retreat_button = _button(self, "↶", func(): retreat_requested.emit())
	retreat_button.add_theme_font_size_override("font_size", 36)
	retreat_button.accessibility_name = "撤退"
	skill_button = _button(self, "", func(): skill_requested.emit())
	skill_button.accessibility_name = "释放技能"
	skill_button.expand_icon = true
	skill_button.add_theme_constant_override("icon_max_width", 44)
	deployment_cancel_button = _button(self, "↶", func(): cancel_requested.emit())
	deployment_cancel_button.add_theme_font_size_override("font_size", 36)
	deployment_cancel_button.accessibility_name = "取消部署"
	deployment_cancel_button.tooltip_text = "取消部署"
	for button in [retreat_button, skill_button, deployment_cancel_button]:
		button.custom_minimum_size = Vector2(56, 56)
		button.size = Vector2(56, 56)
		button.z_index = 10
		button.hide()
	normal_skill_style = skill_button.get_theme_stylebox("normal")
	ready_skill_style = StyleBoxFlat.new()
	ready_skill_style.bg_color = Color("61451c")
	ready_skill_style.border_color = Color("ffd66c")
	ready_skill_style.set_border_width_all(2)
	ready_skill_style.shadow_color = Color(1.0, 0.69, 0.2, 0.45)
	ready_skill_style.shadow_size = 8
	info_panel.hide()
	game_menu = _panel_container()
	game_menu.position = Vector2(18, 110)
	var menu_items := VBoxContainer.new()
	game_menu.add_child(menu_items)
	_button(menu_items, "退出战斗", func(): menu_requested.emit())
	if not replay_mode: _button(menu_items, "重新开始", func(): game_menu.hide(); replay_requested.emit())
	game_menu.hide()
	developer_panel = _panel_container()
	developer_panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	developer_panel.offset_left = 18; developer_panel.offset_right = 318
	developer_panel.offset_top = -120; developer_panel.offset_bottom = -18
	developer_panel.z_index = 20
	var developer_items := VBoxContainer.new()
	developer_panel.add_child(developer_items)
	var developer_header := HBoxContainer.new()
	developer_items.add_child(developer_header)
	var developer_title := _label(developer_header, "开发者面板", 22)
	developer_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	debug_victory_button = _button(developer_items, "跳过战斗并胜利", func():
		debug_victory_requested.emit())
	developer_panel.visible = developer_tools_enabled and not replay_mode
	end_panel = _panel_container()
	end_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	var ending := VBoxContainer.new()
	end_panel.add_child(ending)
	end_label = _label(ending, "", 32)
	result_button = _button(ending, "重新挑战", func():
		if result_victory or replay_mode: continue_requested.emit()
		else: replay_requested.emit())
	end_panel.hide()
	resized.connect(_fit)
	_fit()
	get_window().focus_exited.connect(func():
		if not pressed_roster.is_empty():
			cancel_drag()
			cancel_requested.emit())

func _card_input(key: String, event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed and not cards[key].button.disabled:
		suppress_card_click = false
		pressed_roster = key
		drag_origin = cards[key].button.get_global_transform() * event.position

func _input(event: InputEvent) -> void:
	if pressed_roster.is_empty(): return
	if (event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE) or (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT):
		cancel_drag()
		cancel_requested.emit()
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion:
		if dragged_roster.is_empty() and event.position.distance_to(drag_origin) >= 8:
			_begin_card_drag(pressed_roster)
		if not dragged_roster.is_empty():
			drag_preview.position = event.position - global_position
			roster_drag_hovered.emit(Vector2(-99999,-99999) if _over_ui(event.position) else event.position)
	elif event is InputEventMouseButton and not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if not dragged_roster.is_empty():
			var key := dragged_roster
			if not cards[key].button.disabled and not _over_ui(event.position) and drop_hit_test.is_valid() and drop_hit_test.call(key, event.position):
				roster_dropped.emit(key, event.position)
			else: cancel_requested.emit()
		# Keep the suppression through this event's GUI dispatch, so returning a
		# dragged card onto itself cannot also trigger a normal card click.
		cancel_drag.call_deferred()

func _begin_card_drag(key: String) -> void:
	if cards[key].button.disabled or not cards[key].button.visible: return
	suppress_card_click = true
	dragged_roster = key
	drag_preview = Control.new()
	drag_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	drag_preview.z_index = 30
	add_child(drag_preview)
	var portrait := TextureRect.new()
	portrait.texture = catalog[key].poses[0]
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.size = Vector2(110,130)
	portrait.position = Vector2(-55,-120)
	portrait.modulate.a = 0.8
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	drag_preview.add_child(portrait)
	roster_drag_started.emit(key)

func cancel_drag() -> void:
	var was_dragging := not dragged_roster.is_empty()
	pressed_roster = ""; dragged_roster = ""
	if is_instance_valid(drag_preview): drag_preview.queue_free()
	drag_preview = null
	if was_dragging: roster_drag_ended.emit()

func _over_ui(point: Vector2) -> bool:
	var hovered := get_viewport().gui_get_hovered_control()
	if hovered and hovered != self and not is_ancestor_of(hovered): return true
	for control in [top, bottom, readouts, retreat_button, skill_button, info_panel, deployment_cancel_button, end_panel, game_menu, developer_panel, get_node("Economy")]:
		if control.visible and control.get_global_rect().has_point(point): return true
	return false

func _fit() -> void:
	if not deployment_cancel_button: return
	_position_deployment_cancel()
	end_panel.position = (size - end_panel.size) / 2
	var compact := size.x < 1100
	var card_size := Vector2(82, 112) if compact else Vector2(104, 136)
	for card in cards.values(): card.button.custom_minimum_size = card_size
	bottom.offset_left = -(card_size.x * cards.size() + 5 * (cards.size() - 1) + 18)
	bottom.offset_top = -card_size.y - 14
	var economy_panel := get_node("Economy") as Control
	economy_panel.offset_top = bottom.offset_top - 124
	economy_panel.offset_bottom = bottom.offset_top - 8
	status.add_theme_font_size_override("font_size", roundi((18 if compact else 22) * 1.2))
	life_status.add_theme_font_size_override("font_size", roundi((18 if compact else 22) * 1.2))
	operator_portrait.custom_minimum_size.y = 112 if compact else 160
	info_panel.size = Vector2(300, 0)
	_center_info_panel()

func _center_info_panel() -> void:
	info_panel.position = Vector2(18, (size.y - info_panel.size.y) * 0.5)
	_position_operator_actions()

## Screen coordinates supplied by the game; HUD does not access the 3D scene.
func set_operator_anchor(point: Vector2) -> void:
	operator_anchor = point - global_position
	_position_operator_actions()

func _position_operator_actions() -> void:
	if not retreat_button: return
	for entry in [[retreat_button, Vector2(-86, -80)], [skill_button, Vector2(38, 20)]]:
		var button: Button = entry[0]
		button.position = operator_anchor + entry[1]
		button.position = button.position.clamp(Vector2(8, 64), size - button.size - Vector2(8, 8))
		if info_panel.visible and button.get_rect().intersects(info_panel.get_rect()):
			button.position.x = info_panel.get_rect().end.x + 8


func _label(parent: Node, value: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color("e8efea"))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label

func _status_icon(parent: Node, texture: Texture2D) -> void:
	var icon := TextureRect.new()
	icon.texture = texture
	icon.custom_minimum_size = Vector2(34, 34)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(icon)

func _button(parent: Node, value: String, callback: Callable) -> Button:
	var clicked := func():
		ui_sound_requested.emit("sfx_ui_click")
		callback.call()
	var button := action(value, Rect2(), clicked, parent)
	style_battle_button(button)
	button.custom_minimum_size = Vector2(62, 42)
	button.add_theme_font_size_override("font_size", 19)
	return button

func battle_panel_style() -> StyleBox:
	var style: StyleBox
	if panel_texture:
		var textured := StyleBoxTexture.new()
		textured.texture = panel_texture
		textured.texture_margin_left = 14; textured.texture_margin_right = 14
		textured.texture_margin_top = 12; textured.texture_margin_bottom = 12
		style = textured
	else:
		style = _panel()
	style.content_margin_left = 14; style.content_margin_right = 14
	style.content_margin_top = 12; style.content_margin_bottom = 12
	return style

func style_battle_button(button: Button) -> void:
	for state in ["normal", "hover", "pressed", "disabled"]:
		var style := battle_panel_style()
		style.content_margin_left = 8; style.content_margin_right = 8
		style.content_margin_top = 4; style.content_margin_bottom = 4
		if style is StyleBoxTexture:
			if state == "hover": style.modulate_color = Color(1.3, 1.3, 1.3, 1.0)
			if state == "pressed": style.modulate_color = Color(1.5, 1.5, 1.5, 1.0)
			if state == "disabled": style.modulate_color = Color(0.65, 0.65, 0.65, 0.8)
		button.add_theme_stylebox_override(state, style)

func _panel_container() -> PanelContainer:
	var panel := PanelContainer.new()
	var style := battle_panel_style()
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)
	return panel

func set_leak_warning(threatened: bool, flash: float) -> void:
	leak_warning.visible = threatened
	life_status.add_theme_color_override("font_color", Color("e8efea").lerp(Color("ff3f38"), clampf(flash, 0.0, 1.0)))

func update_state(state: Dictionary, chosen_roster: String, chosen_unit: int, speed: float, deploy_limit: int) -> void:
	selected_roster = chosen_roster; selected_unit = chosen_unit
	var finished: bool = state.phase in ["victory", "defeat"]
	status.text = "%d / %d" % [state.killed + state.escaped, state.remaining + state.killed + state.escaped]
	life_status.text = str(state.life)
	objective_label.visible = state.has("objective")
	if state.has("objective"):
		objective_label.text = "节点修复  %d%%" % floori(100.0 * state.objective.elapsed / state.objective.duration)
	economy.text = "◇ %d" % floori(state.cost)
	deployment_count.text = "可部署干员：%d" % maxi(0, deploy_limit - state.units.size())
	set_playback(state.paused, speed)
	pause_button.disabled = finished or replay_mode
	speed_button.disabled = finished
	debug_victory_button.disabled = finished
	if finished: developer_panel.hide()
	var deployed := {}
	var selected := {}
	for unit in state.units:
		deployed[unit.roster_id] = true
		if unit.id == chosen_unit: selected = unit
	var deployed_selection := not selected.is_empty()
	if selected.is_empty() and roster.has(chosen_roster): selected = roster[chosen_roster]
	for key in cards:
		var cooldown: float = state.redeploy[key]
		cards[key].button.visible = not deployed.has(key)
		cards[key].button.disabled = finished or replay_mode or cooldown > 0
		cards[key].portrait.modulate = Color(0.5, 0.5, 0.5) if state.cost < roster[key].cost else Color.WHITE
		cards[key].cooldown.visible = cooldown > 0
		cards[key].timer.text = "%.1f" % cooldown
		cards[key].button.modulate = Color("ffdb8d") if key == chosen_roster else Color.WHITE
		cards[key].value.text = "%d" % roster[key].cost
	info_panel.visible = not selected.is_empty() and not finished
	retreat_button.visible = deployed_selection and not finished
	skill_button.visible = deployed_selection and not finished
	if not selected.is_empty():
		operator_name.text = selected.name
		selection.text = "攻击 %d\n防御 %d\n法抗 %d\n阻挡 %d" % [selected.attack, selected.defense, selected.resistance, selected.block]
		var ready: bool = deployed_selection and selected.skill.enabled and selected.skill.get("trigger", "manual") == "manual" and selected.sp + 0.000001 >= selected.skill.required and selected.skill_left <= 0
		skill_button.disabled = not ready or state.phase != "running"
		var appearance = catalog[selected.roster_id if deployed_selection else chosen_roster]
		operator_portrait.texture = appearance.portrait
		operator_class_icon.texture = appearance.class_icon
		range_preview.cells = selected.range.duplicate()
		if deployed_selection:
			range_preview.cells.clear()
			for cell in selected.range_cells:
				var offset: Vector2i = cell - selected.cell
				for turn in range(selected.facing): offset = Vector2i(offset.y, -offset.x)
				range_preview.cells.append(offset)
		range_preview.queue_redraw()
		skill_button.icon = skill_icons.get(selected.roster_id if deployed_selection else chosen_roster, appearance.portrait)
		skill_portrait.texture = skill_button.icon
		if selected.skill.enabled:
			skill_description.text = "%s提升至 %.0f%%，持续 %.1f 秒。" % ["治疗量" if selected.role == "healer" else "攻击力", selected.skill.multiplier * 100.0, selected.skill.duration]
			if not selected.skill.get("description", "").is_empty():
				skill_description.text = "%s\n%s" % [selected.skill.get("name", "技能"), selected.skill.description]
		else:
			skill_description.text = "无主动技能"
		skill_button.tooltip_text = ""
		if ready: skill_button.add_theme_stylebox_override("normal", ready_skill_style)
		else: skill_button.add_theme_stylebox_override("normal", normal_skill_style)
		var skill_left: float = selected.get("skill_left", 0.0)
		skill_status.visible = skill_left > 0
		skill_status.text = "剩余 %.1fs" % skill_left if skill_left > 0 else ""
		retreat_button.tooltip_text = "撤退"
		_position_operator_actions()
	end_panel.visible = finished
	result_victory = state.phase == "victory"
	result_button.text = "返回关卡" if replay_mode else ("继续" if result_victory else "重新挑战")
	if finished:
		deployment_cancel_button.hide()
		end_label.text = "防守成功" if state.phase == "victory" else "基地失守"
		_fit()

func set_notice(message: String) -> void:
	notice.text = message
	notice.visible = not message.is_empty()

func set_pending_deployment(active: bool, point := Vector2.ZERO) -> void:
	deployment_cancel_button.visible = active
	if active:
		deployment_anchor = point - global_position
		_position_deployment_cancel()

func _position_deployment_cancel() -> void:
	deployment_cancel_button.position = (deployment_anchor + Vector2(-86, -80)).clamp(Vector2(8, 80), size - deployment_cancel_button.size - Vector2(8, 8))
