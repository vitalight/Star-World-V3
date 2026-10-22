extends PanelContainer
## An embedded Control, not an OS Window. Consumes only its own input region.
var game: Node3D
var title_bar: HBoxContainer
var inspect: Label
var event_log: Label
var events: Array = []
var grid: CheckBox
var routes: CheckBox
var ranges: CheckBox
var dragging := false
var resizing := false

func _ready() -> void:
	position = Vector2(30, 115)
	size = Vector2(470, 500)
	custom_minimum_size = Vector2(340, 280)
	z_index = 40
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_ALL
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.055, 0.075, 0.10, 0.97)
	style.border_color = Color("799789")
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.content_margin_left = 14; style.content_margin_right = 14
	style.content_margin_top = 10; style.content_margin_bottom = 18
	add_theme_stylebox_override("panel", style)
	var body := VBoxContainer.new()
	add_child(body)
	title_bar = HBoxContainer.new()
	title_bar.mouse_default_cursor_shape = Control.CURSOR_MOVE
	title_bar.gui_input.connect(_drag_title)
	body.add_child(title_bar)
	var title := Label.new(); title.text = "GAME TEST  /  战斗调试"
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_bar.add_child(title)
	button(title_bar, "×", hide)
	var controls := HFlowContainer.new(); body.add_child(controls)
	button(controls, "开始", func(): game.start())
	button(controls, "暂停/继续", func(): game.toggle_pause())
	button(controls, "单步", func(): game.step())
	for speed in [1.0, 2.0, 4.0]: button(controls, "%d×" % int(speed), func(): game.set_speed(speed))
	button(controls, "重置", func(): events.clear(); game.reset())
	button(controls, "重新加载关卡", func(): events.clear(); game.reload_level())
	var switches := HBoxContainer.new(); body.add_child(switches)
	grid = checkbox(switches, "网格", false)
	routes = checkbox(switches, "路线", false)
	ranges = checkbox(switches, "范围", true)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body.add_child(scroll)
	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(content)
	inspect = Label.new(); inspect.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(inspect)
	event_log = Label.new(); event_log.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(event_log)
	var handle := Button.new(); handle.text = "◢"; handle.mouse_default_cursor_shape = Control.CURSOR_FDIAGSIZE
	handle.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	handle.offset_left = -24; handle.offset_top = -24
	handle.gui_input.connect(_resize_handle)
	var resize_overlay := Control.new()
	resize_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(resize_overlay)
	resize_overlay.add_child(handle)
	game.observed.connect(_observe)
	get_parent().resized.connect(clamp_rect)
	clamp_rect()

func button(parent: Node, value: String, callback: Callable) -> Button:
	var result := Button.new(); result.text = value
	result.custom_minimum_size.y = 30
	result.pressed.connect(callback)
	parent.add_child(result)
	return result

func checkbox(parent: Node, value: String, enabled: bool) -> CheckBox:
	var result := CheckBox.new(); result.text = value; result.button_pressed = enabled
	result.toggled.connect(func(_enabled): game.set_debug(grid.button_pressed, routes.button_pressed, ranges.button_pressed))
	parent.add_child(result)
	return result

func _observe(state: Dictionary, batch: Array) -> void:
	if state.time == 0 and state.phase == "ready": events.clear()
	events.append_array(batch)
	while events.size() > 12: events.pop_front()
	if not visible: return
	var unit: Dictionary = game.battle.find_unit(game.selected_unit)
	inspect.text = "状态 %s  暂停 %s  %.2fs\n生命 %d  费用 %.1f  在场 %d/%d\n选中单位\n%s\n\n最近事件" % [state.phase, state.paused, state.time, state.life, state.cost, state.units.size(), state.enemies.size(), str(unit) if not unit.is_empty() else "无"]
	var lines := PackedStringArray()
	for event in events:
		lines.append("%.2f  %s  #%s → #%s" % [event.time, event.type, event.get("source", "-"), event.get("target", "-")])
	event_log.text = "\n".join(lines)

func clamp_rect() -> void:
	var available: Vector2 = get_parent().size
	size = size.clamp(Vector2(340, 280), available.max(Vector2(340, 280)))
	position = position.clamp(Vector2.ZERO, (available - size).max(Vector2.ZERO))

func _drag_title(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		dragging = event.pressed
		grab_focus()
		accept_event()
	elif event is InputEventMouseMotion and dragging:
		position += event.relative
		clamp_rect(); accept_event()

func _resize_handle(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		resizing = event.pressed
		grab_focus(); accept_event()
	elif event is InputEventMouseMotion and resizing:
		size += event.relative
		clamp_rect(); accept_event()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventKey: accept_event()
