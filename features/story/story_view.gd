extends Control
## Presentation only. The caller supplies textures and a story-session snapshot.
signal advance_requested
signal choice_requested(index: int)
const INK = Color("f4f1eb")
const ACCENT = Color("dfc49b")
var background: TextureRect
var actor_views: Array[TextureRect] = []
var speaker: Label
var dialogue: Label
var choices: VBoxContainer
var continue_button: Button
var ending: Label
var _dialogue_scroll: ScrollContainer
var _backgrounds: Dictionary = {}
var _actors: Dictionary = {}
var _state: Dictionary = {}

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background = _texture()
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for index in 2:
		var actor := _texture()
		actor.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		actor_views.append(actor)
	_gradient([Color(0, 0, 0, 0.62), Color.TRANSPARENT], [0.0, 1.0], true)
	_gradient([Color.TRANSPARENT, Color(0, 0, 0, 0.78), Color.BLACK], [0.58, 0.82, 1.0], false)
	speaker = _label(28, ACCENT)
	_dialogue_scroll = ScrollContainer.new()
	_dialogue_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(_dialogue_scroll)
	dialogue = _label(24, INK, _dialogue_scroll)
	dialogue.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	choices = VBoxContainer.new()
	choices.add_theme_constant_override("separation", 12)
	add_child(choices)
	continue_button = _button("继续 →", self)
	continue_button.pressed.connect(func(): advance_requested.emit())
	ending = _label(16, Color("aaa9a8"))
	ending.text = "— 本段剧情结束 —"
	ending.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	resized.connect(_layout)
	_layout()
	if not _state.is_empty():
		show_snapshot(_state)

func configure(backgrounds: Dictionary, actors: Dictionary) -> void:
	_backgrounds = backgrounds.duplicate()
	_actors = actors.duplicate()

func show_snapshot(state: Dictionary) -> void:
	_state = state.duplicate(true)
	if not is_node_ready() or state.is_empty():
		return
	background.texture = _backgrounds.get(state.get("background", ""))
	var visible_actors: Array = state.get("actors", [])
	for index in actor_views.size():
		var actor: TextureRect = actor_views[index]
		actor.visible = index < visible_actors.size()
		if actor.visible:
			var key: String = visible_actors[index]
			actor.texture = _actors.get(key)
			var active: String = state.get("speaker_actor", "")
			actor.modulate = Color.WHITE if active.is_empty() or active == key else Color(0.53, 0.57, 0.64)
	speaker.text = state.get("speaker", "旁白")
	dialogue.text = state.get("text", "")
	_dialogue_scroll.scroll_vertical = 0
	continue_button.visible = state.get("type") == "line"
	ending.visible = state.get("type") == "end"
	for child in choices.get_children():
		choices.remove_child(child)
		child.queue_free()
	if state.get("type") == "choice":
		var options: Array = state.get("choices", [])
		for index in options.size():
			var button := _button(options[index].text, choices)
			button.custom_minimum_size.y = 52
			button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			button.pressed.connect(func(): choice_requested.emit(index))
	_layout()

func _texture() -> TextureRect:
	var view := TextureRect.new()
	view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	view.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	add_child(view)
	return view

func _gradient(colors: Array, offsets: Array, top: bool) -> void:
	var ramp := Gradient.new()
	ramp.colors = PackedColorArray(colors)
	ramp.offsets = PackedFloat32Array(offsets)
	var texture := GradientTexture2D.new()
	texture.gradient = ramp
	texture.fill_from = Vector2(0, 0)
	texture.fill_to = Vector2(0, 1)
	var view := _texture()
	view.texture = texture
	view.stretch_mode = TextureRect.STRETCH_SCALE
	view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if top:
		view.anchor_bottom = 0.24

func _label(font_size: int, color: Color, parent: Node = null) -> Label:
	if parent == null:
		parent = self
	var label := Label.new()
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 2)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label

func _button(text: String, parent: Node) -> Button:
	var button := Button.new()
	button.text = text
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_font_size_override("font_size", 18)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.02, 0.025, 0.035, 0.83)
	style.border_color = Color(0.75, 0.72, 0.64, 0.48)
	style.set_border_width_all(1)
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	button.add_theme_stylebox_override("normal", style)
	var hover := style.duplicate()
	hover.bg_color = Color(0.21, 0.19, 0.14, 0.95)
	hover.border_color = ACCENT
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)
	parent.add_child(button)
	return button

func _layout() -> void:
	if not is_node_ready():
		return
	var count: int = mini(_state.get("actors", []).size(), 2)
	var actor_height := size.y * 0.82
	var actor_width := minf(size.x * (0.58 if count == 1 else 0.46), actor_height * 1.1)
	for index in actor_views.size():
		var center_x: float = size.x * (0.5 if count == 1 else [0.31, 0.69][index])
		actor_views[index].position = Vector2(center_x - actor_width * 0.5, size.y * 0.94 - actor_height)
		actor_views[index].size = Vector2(actor_width, actor_height)
	var inset := maxf(28, size.x * 0.12)
	var text_width := size.x - inset * 2
	var compact := size.x < 1000 or size.y < 700
	var speaker_y := size.y * (0.72 if compact else 0.785)
	var text_y := speaker_y + (40 if compact else 46)
	speaker.position = Vector2(inset, speaker_y)
	speaker.size = Vector2(text_width, 38)
	speaker.add_theme_font_size_override("font_size", 25 if size.x < 1000 else 28)
	_dialogue_scroll.position = Vector2(inset, text_y)
	_dialogue_scroll.size = Vector2(text_width, maxf(38, size.y - 72 - text_y))
	dialogue.add_theme_font_size_override("font_size", 20 if size.x < 1000 else 24)
	var choice_width := minf(660, size.x * 0.74)
	choices.position = Vector2((size.x - choice_width) * 0.5, size.y * 0.49)
	choices.size.x = choice_width
	continue_button.position = Vector2(size.x - inset - 125, size.y - 58)
	continue_button.size = Vector2(125, 46)
	ending.position = Vector2(inset, size.y - 43)
	ending.size = Vector2(text_width, 28)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		advance_requested.emit()
		accept_event()
