extends Control
## 1280x720 display canvas. Only presentation intents leave this component.
signal pause_requested
signal speed_requested
signal replay_requested
signal reset_speed_requested
var readout := {"progress": "--", "life": "--", "cost": "--", "available": "--"}
var portraits: Array[Texture2D] = []
var card_costs: PackedInt32Array = []
var card_symbols: PackedStringArray = []
var card_cooldowns: PackedFloat32Array = []
var pause_button: Button
var speed_button: Button
var settings: Panel

func action(text: String, rect: Rect2, callback: Callable, parent: Node = self) -> Button:
	var button := Button.new()
	button.text = text
	button.position = rect.position
	button.size = rect.size
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_font_size_override("font_size", 25)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("172831e8")
	style.border_color = Color("66818a")
	style.set_border_width_all(1)
	style.corner_radius_top_left = 4
	style.corner_radius_bottom_right = 4
	style.content_margin_left = 12; style.content_margin_right = 12
	style.content_margin_top = 6; style.content_margin_bottom = 6
	button.add_theme_stylebox_override("normal", style)
	var hover := style.duplicate()
	hover.bg_color = Color("31505a")
	hover.border_color = Color("b4d4d5")
	button.add_theme_stylebox_override("hover", hover)
	var pressed := style.duplicate()
	pressed.bg_color = Color("4b6260")
	button.add_theme_stylebox_override("pressed", pressed)
	var disabled := style.duplicate()
	disabled.bg_color = Color("17232bcc")
	disabled.border_color = Color("44535a")
	button.add_theme_stylebox_override("disabled", disabled)
	var focus := StyleBoxFlat.new()
	focus.bg_color = Color.TRANSPARENT
	focus.border_color = Color("f5cf83")
	focus.set_border_width_all(2)
	button.add_theme_stylebox_override("focus", focus)
	button.add_theme_color_override("font_color", Color("edf3e9"))
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.pressed.connect(callback)
	parent.add_child(button)
	return button

func _ready() -> void:
	size = Vector2(1280, 720)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var vignette := ColorRect.new()
	vignette.size = size
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shade := ShaderMaterial.new()
	shade.shader = preload("res://features/battle_hud/vignette.gdshader")
	vignette.material = shade
	add_child(vignette)
	action("☰", Rect2(22, 16, 62, 52), func(): settings.visible = not settings.visible)
	speed_button = action("1×", Rect2(1080, 16, 78, 52), func(): speed_requested.emit())
	pause_button = action("", Rect2(1174, 16, 78, 52), func(): pause_requested.emit())
	for i in portraits.size():
		var card := action("", Rect2(628 + i * 123, 590, 117, 130), func(): pass)
		card.tooltip_text = "展示角色 · 预览素材"
		card.clip_contents = true
		var portrait := TextureRect.new()
		portrait.position = Vector2(0, 27)
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.texture = portraits[i]
		portrait.size = Vector2(117, 103)
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(portrait)
		var value := Label.new()
		value.text = "%s %d" % [card_symbols[i] if i < card_symbols.size() else "◇", card_costs[i] if i < card_costs.size() else 0]
		value.position = Vector2(8, 0)
		value.add_theme_font_size_override("font_size", 23)
		value.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(value)
		if i < card_cooldowns.size() and card_cooldowns[i] > 0:
			var cooldown := ColorRect.new()
			cooldown.color = Color(0.12, 0.07, 0.08, 0.65)
			cooldown.position = Vector2(0, 35)
			cooldown.size = Vector2(117, 95)
			cooldown.mouse_filter = Control.MOUSE_FILTER_IGNORE
			card.add_child(cooldown)
			var seconds := Label.new()
			seconds.text = "%.1f" % card_cooldowns[i]
			seconds.position = Vector2(30, 55)
			cooldown.add_child(seconds)
	settings = Panel.new()
	settings.position = Vector2(25, 80)
	settings.size = Vector2(280, 165)
	add_child(settings)
	action("重播展示", Rect2(15, 15, 240, 56), func(): replay_requested.emit(), settings)
	action("恢复 1×", Rect2(15, 85, 240, 56), func(): reset_speed_requested.emit(), settings)
	settings.hide()
	set_playback(false, 1.0)

func set_playback(paused: bool, speed: float) -> void:
	if pause_button:
		pause_button.icon = preload("res://features/battle_hud/play.svg") if paused else preload("res://features/battle_hud/pause.svg")
		pause_button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		pause_button.accessibility_name = "继续" if paused else "暂停"
		pause_button.add_theme_constant_override("icon_max_width", 26)
		speed_button.text = "%d×" % int(speed)

func set_readout(values: Dictionary) -> void:
	readout.merge(values, true)
	queue_redraw()

func status_readout(progress: String, life: String) -> String:
	return "⚑  " + progress + "      ♜  " + life

func _draw() -> void:
	var font := ThemeDB.fallback_font
	draw_style_box(_panel(), Rect2(465, 12, 350, 43))
	draw_string(font, Vector2(489, 42), status_readout(readout.progress, readout.life), HORIZONTAL_ALIGNMENT_LEFT, -1, 26)
	draw_style_box(_panel(), Rect2(1080, 479, 178, 95))
	draw_string(font, Vector2(1132, 522), "◇ " + readout.cost, HORIZONTAL_ALIGNMENT_LEFT, -1, 37)
	draw_string(font, Vector2(1090, 554), "可部署角色：" + readout.available, HORIZONTAL_ALIGNMENT_LEFT, -1, 18)
	for i in 12:
		draw_rect(Rect2(i * 4, i * 3, 1280 - i * 8, 720 - i * 6), Color(0.025, 0.025, 0.03, 0.014), false, 8)

func _panel() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("10232de8")
	style.border_color = Color("536e78")
	style.set_border_width_all(1)
	style.corner_radius_top_left = 4
	style.corner_radius_bottom_right = 4
	style.shadow_color = Color(0.01, 0.03, 0.04, 0.35)
	style.shadow_size = 4
	return style
