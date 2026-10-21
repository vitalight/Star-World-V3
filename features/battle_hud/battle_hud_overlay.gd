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
	style.bg_color = Color(0.07, 0.09, 0.10, 0.83)
	style.skew = Vector2(-0.13, 0)
	button.add_theme_stylebox_override("normal", style)
	var hover := style.duplicate()
	hover.bg_color = Color(0.25, 0.32, 0.34, 0.95)
	button.add_theme_stylebox_override("hover", hover)
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
	pause_button = action("Ⅱ", Rect2(1174, 16, 78, 52), func(): pause_requested.emit())
	for i in portraits.size():
		var card := action("", Rect2(628 + i * 123, 590, 117, 130), func(): pass)
		card.tooltip_text = "展示角色 · 预览素材"
		card.clip_contents = true
		var portrait := TextureRect.new()
		portrait.position = Vector2(0, 15)
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		var source := portraits[i].get_image()
		var extent := source.get_size()
		portrait.texture = ImageTexture.create_from_image(source.get_region(Rect2i(int(extent.x * 0.15), 0, int(extent.x * 0.7), int(extent.y * 0.65))))
		portrait.size = Vector2(117, 110)
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

func set_playback(paused: bool, speed: float) -> void:
	if pause_button:
		pause_button.text = "▶" if paused else "Ⅱ"
		speed_button.text = "%d×" % int(speed)

func set_readout(values: Dictionary) -> void:
	readout.merge(values, true)
	queue_redraw()

func _draw() -> void:
	var font := ThemeDB.fallback_font
	draw_style_box(_panel(), Rect2(465, 12, 350, 43))
	draw_string(font, Vector2(489, 42), "⚑  " + readout.progress + "      ♜  " + readout.life, HORIZONTAL_ALIGNMENT_LEFT, -1, 26)
	draw_style_box(_panel(), Rect2(1080, 479, 178, 95))
	draw_string(font, Vector2(1132, 522), "◇ " + readout.cost, HORIZONTAL_ALIGNMENT_LEFT, -1, 37)
	draw_string(font, Vector2(1090, 554), "可部署角色：" + readout.available, HORIZONTAL_ALIGNMENT_LEFT, -1, 18)
	for i in 12:
		draw_rect(Rect2(i * 4, i * 3, 1280 - i * 8, 720 - i * 6), Color(0.025, 0.025, 0.03, 0.014), false, 8)

func _panel() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.075, 0.085, 0.76)
	style.skew = Vector2(-0.12, 0)
	return style
