extends "res://features/battle_hud/battle_hud_overlay.gd"
## Interactive variant sharing the Art Test HUD's styles and playback intents.
signal start_requested
signal roster_selected(roster_id: String)
signal roster_drag_started(roster_id: String)
signal roster_drag_hovered(point: Vector2)
signal roster_dropped(roster_id: String, point: Vector2)
signal facing_selected(facing: int)
signal deploy_confirmed
signal cancel_requested
signal retreat_requested
signal skill_requested
signal menu_requested
var dragged_roster := ""
var pressed_roster := ""
var suppress_card_click := false
var drag_origin := Vector2.ZERO
var drag_preview: Control
var drop_hit_test: Callable
var readouts: VBoxContainer
var cards := {}
var status: Label
var notice: Label
var selection: Label
var start_button: Button
var retreat_button: Button
var skill_button: Button
var skill_status: Label
var ready_skill_style: StyleBoxFlat
var direction_panel: PanelContainer
var end_panel: PanelContainer
var end_label: Label
var roster: Dictionary
var catalog: Dictionary
var selected_roster := ""
var selected_unit := -1
var info_panel: PanelContainer
var top: HBoxContainer
var bottom: HBoxContainer
var economy: Label
var deployment_count: Label
var game_menu: PanelContainer

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
	_button(top, "☰", func(): game_menu.visible = not game_menu.visible)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(spacer)
	speed_button = _button(top, "1×", func(): speed_requested.emit())
	pause_button = _button(top, "Ⅱ", func(): pause_requested.emit())
	var progress := _panel_container()
	progress.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	progress.offset_left = -165; progress.offset_right = 165
	progress.offset_top = 12; progress.offset_bottom = 58
	progress.mouse_filter = Control.MOUSE_FILTER_IGNORE
	status = _label(progress, "准备部署", 22)
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	readouts = VBoxContainer.new()
	readouts.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	readouts.offset_left = 18; readouts.offset_right = 285
	readouts.offset_top = -100; readouts.offset_bottom = -18
	readouts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(readouts)
	notice = _label(readouts, "点击或拖动干员卡部署", 16)
	notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	start_button = _button(readouts, "开始战斗", func(): start_requested.emit())
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
	economy.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	deployment_count = _label(economy_rows, "", 22)
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
		card.tooltip_text = roster[key].name + (" · 仅限地面" if roster[key].get("role", "melee") == "melee" else " · 仅限高台")
		card.add_theme_stylebox_override("normal", _panel())
		card.pressed.connect(func():
			if not suppress_card_click: roster_selected.emit(key))
		card.gui_input.connect(func(event): _card_input(key, event))
		bottom.add_child(card)
		var portrait := TextureRect.new()
		var texture: Texture2D = catalog[key].portrait
		var crop := AtlasTexture.new()
		crop.atlas = texture
		crop.region = Rect2(texture.get_size() * Vector2(0.18, 0.02), texture.get_size() * Vector2(0.64, 0.57))
		portrait.texture = crop
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		portrait.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		portrait.offset_top = 16
		portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(portrait)
		var strip := ColorRect.new()
		strip.color = Color(0.05, 0.08, 0.09, 0.88)
		strip.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
		strip.offset_bottom = 27
		strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(strip)
		var value := _label(card, "◇ %d" % roster[key].cost, 20)
		value.position = Vector2(7, 0)
		var title := _label(card, roster[key].name, 15)
		title.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
		title.offset_top = -25
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title.add_theme_color_override("font_shadow_color", Color.BLACK)
		title.add_theme_constant_override("shadow_offset_x", 1)
		title.add_theme_constant_override("shadow_offset_y", 1)
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
		cards[key] = {"button": card, "value": value, "cooldown": cooldown, "timer": timer, "portrait": portrait}
	info_panel = _panel_container()
	info_panel.position = Vector2(18, 90)
	info_panel.custom_minimum_size = Vector2(235, 0)
	var info := VBoxContainer.new()
	info_panel.add_child(info)
	selection = _label(info, "", 17)
	retreat_button = _button(info, "撤退", func(): retreat_requested.emit())
	skill_status = _label(info, "", 16)
	skill_button = _button(info, "释放技能", func(): skill_requested.emit())
	skill_button.custom_minimum_size = Vector2(210, 72)
	skill_button.expand_icon = true
	skill_button.add_theme_constant_override("icon_max_width", 52)
	ready_skill_style = _panel()
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
	_button(menu_items, "关闭菜单", func(): game_menu.hide())
	_button(menu_items, "重新开始", func(): game_menu.hide(); replay_requested.emit())
	_button(menu_items, "Developer Hub", func(): menu_requested.emit())
	game_menu.hide()
	direction_panel = _panel_container()
	direction_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	direction_panel.position = size / 2 - Vector2(150, 100)
	var choices := VBoxContainer.new()
	direction_panel.add_child(choices)
	_label(choices, "移动鼠标定向，左键确认", 18)
	var directions := HBoxContainer.new()
	choices.add_child(directions)
	for facing in 4:
		_button(directions, ["→", "↓", "←", "↑"][facing], func(): facing_selected.emit(facing))
	_button(choices, "确认部署", func(): deploy_confirmed.emit())
	_button(choices, "取消", func(): cancel_requested.emit())
	direction_panel.hide()
	end_panel = _panel_container()
	end_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	var ending := VBoxContainer.new()
	end_panel.add_child(ending)
	end_label = _label(ending, "", 32)
	_button(ending, "重新挑战", func(): replay_requested.emit())
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
	pressed_roster = ""; dragged_roster = ""
	if is_instance_valid(drag_preview): drag_preview.queue_free()
	drag_preview = null

func _over_ui(point: Vector2) -> bool:
	var hovered := get_viewport().gui_get_hovered_control()
	if hovered and hovered != self and not is_ancestor_of(hovered): return true
	for control in [top, bottom, readouts, info_panel, direction_panel, end_panel, game_menu, get_node("Economy")]:
		if control.visible and control.get_global_rect().has_point(point): return true
	return false

func _fit() -> void:
	if not direction_panel: return
	direction_panel.position = Vector2(18, 150)
	end_panel.position = (size - end_panel.size) / 2
	var compact := size.x < 1100
	var card_size := Vector2(82, 112) if compact else Vector2(104, 136)
	for card in cards.values(): card.button.custom_minimum_size = card_size
	bottom.offset_left = -(card_size.x * cards.size() + 5 * (cards.size() - 1) + 18)
	bottom.offset_top = -card_size.y - 14
	var economy_panel := get_node("Economy") as Control
	economy_panel.offset_top = bottom.offset_top - 124
	economy_panel.offset_bottom = bottom.offset_top - 8
	status.add_theme_font_size_override("font_size", 18 if compact else 22)

func _label(parent: Node, value: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color("e5e4cd"))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label

func _button(parent: Node, value: String, callback: Callable) -> Button:
	var button := action(value, Rect2(), callback, parent)
	button.custom_minimum_size = Vector2(62, 42)
	button.add_theme_font_size_override("font_size", 19)
	return button

func _panel_container() -> PanelContainer:
	var panel := PanelContainer.new()
	var style := _panel()
	style.skew = Vector2.ZERO
	style.content_margin_left = 14; style.content_margin_right = 14
	style.content_margin_top = 12; style.content_margin_bottom = 12
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)
	return panel

func update_state(state: Dictionary, chosen_roster: String, chosen_unit: int, speed: float, deploy_limit: int) -> void:
	selected_roster = chosen_roster; selected_unit = chosen_unit
	var finished: bool = state.phase in ["victory", "defeat"]
	status.text = status_readout("%d / %d" % [state.killed + state.escaped, state.remaining + state.killed + state.escaped], str(state.life))
	economy.text = "◇ %d" % floori(state.cost)
	deployment_count.text = "可部署干员：%d" % maxi(0, deploy_limit - state.units.size())
	set_playback(state.paused, speed)
	pause_button.disabled = state.phase != "running"
	speed_button.disabled = finished
	start_button.visible = state.phase == "ready"
	var deployed := {}
	var selected := {}
	for unit in state.units:
		deployed[unit.roster_id] = true
		if unit.id == chosen_unit: selected = unit
	for key in cards:
		var cooldown: float = state.redeploy[key]
		cards[key].button.visible = not deployed.has(key)
		cards[key].button.disabled = finished or cooldown > 0 or state.cost < roster[key].cost
		cards[key].portrait.modulate = Color(0.5, 0.5, 0.5) if state.cost < roster[key].cost else Color.WHITE
		cards[key].cooldown.visible = cooldown > 0
		cards[key].timer.text = "%.1f" % cooldown
		cards[key].button.modulate = Color("ffdb8d") if key == chosen_roster else Color.WHITE
		cards[key].value.text = "◇ %d" % roster[key].cost
	info_panel.visible = not selected.is_empty() and not finished
	if not selected.is_empty():
		selection.text = "%s\n生命 %d / %d\n阻挡 %d / %d\n技力 %.1f / %.1f\n技能剩余 %.1fs" % [selected.name, ceili(selected.hp), ceili(selected.max_hp), selected.blocked.size(), selected.block, selected.sp, selected.skill.required, selected.skill_left]
		var ready: bool = selected.skill.enabled and selected.sp + 0.000001 >= selected.skill.required and selected.skill_left <= 0
		skill_button.disabled = not ready or state.phase != "running"
		var appearance = catalog[selected.roster_id]
		skill_button.icon = appearance.skill_icon if appearance.skill_icon else appearance.portrait
		skill_button.tooltip_text = "点击技能图标释放" if ready else "技力充满后可释放"
		if ready: skill_button.add_theme_stylebox_override("normal", ready_skill_style)
		else: skill_button.add_theme_stylebox_override("normal", _panel())
		if not selected.skill.enabled: skill_status.text = "无主动技能"
		elif selected.skill_left > 0: skill_status.text = "技能持续中 · %.1fs" % selected.skill_left
		elif state.phase != "running": skill_status.text = "开始战斗后可释放" if ready else "技力充能中"
		elif ready: skill_status.text = "技能就绪 · 点击图标释放"
		else: skill_status.text = "技力充能中 · %.1f / %.1f" % [selected.sp, selected.skill.required]
		skill_status.add_theme_color_override("font_color", Color("ffe08a") if ready else Color("bdc8c7"))
		retreat_button.tooltip_text = "返还一半部署费用（向下取整，受费用上限限制）；再部署冷却 %.1f 秒" % selected.redeploy_time
		selection.text += "\n撤退返费 ◇%d（受上限限制）\n再部署冷却 %.1fs" % [floori(selected.cost * 0.5), selected.redeploy_time]
	end_panel.visible = finished
	if finished:
		direction_panel.hide()
		end_label.text = "防守成功" if state.phase == "victory" else "基地失守"
		_fit()
