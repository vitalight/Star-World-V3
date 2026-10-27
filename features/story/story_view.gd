extends Control
## Presentation only. The caller supplies textures and a story-session snapshot.
signal advance_requested
signal choice_requested(index: int)
signal ui_sound_requested(id: String)
const INK = Color("f4f1eb")
const ACCENT = Color("dfc49b")
var background: TextureRect
var _previous_background: TextureRect
var _background_base: Texture2D
var _background_region := Rect2()
var _background_region_from := Rect2()
var _background_region_to := Rect2()
var _background_crop: AtlasTexture
var _framing_transition := false
var _background_fade := false
var _fade_start := 0.0
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
var _stage: Control
var _move_from: Dictionary = {}
var _effect_time := 0.0
var _anim_screen_shake := false
var _anim_actor_shake: Array = []
var _anim_actor_flip: Array = []
var _actor_mirror: Array = []
var _anim_actor_exit_left: Array = []
var _anim_actor_exit_right: Array = []
const BACKGROUND_TRANSITION_DURATION := 0.35
const ACTOR_MOVE_DURATION := 0.3
const SCREEN_SHAKE_DURATION := 0.55
const ACTOR_SHAKE_DURATION := 0.36
const ACTOR_FLIP_DURATION := 0.24
const ACTOR_EXIT_DELAY := 0.3
const ACTOR_EXIT_DURATION := 0.45

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	clip_contents = true
	_stage = Control.new()
	_stage.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_stage)
	_previous_background = _texture(_stage)
	_previous_background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_previous_background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_previous_background.visible = false
	background = _texture(_stage)
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for index in 2:
		var actor := _texture(_stage)
		actor.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		actor_views.append(actor)
	_gradient([Color(0, 0, 0, 0.62), Color(0, 0, 0, 0)], [0.0, 1.0], true)
	_gradient([Color(0, 0, 0, 0), Color(0, 0, 0, 0.78), Color.BLACK], [0.58, 0.82, 1.0], false)
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
	set_process(false)
	if not _state.is_empty():
		show_snapshot(_state)

func configure(backgrounds: Dictionary, actors: Dictionary) -> void:
	_backgrounds = backgrounds.duplicate()
	_actors = actors.duplicate()

func show_snapshot(state: Dictionary) -> void:
	# Keep the current displayed layout by identity, including a move interrupted
	# by rapid advance. Shakes and outgoing actors are not carried forward.
	var previous := {}
	var previous_facing := {}
	if is_node_ready() and size.x > 0.0 and size.y > 0.0:
		var old_actors: Array = _state.get("actors", [])
		for index in mini(old_actors.size(), actor_views.size()):
			var key: String = old_actors[index]
			if actor_views[index].visible and not _anim_actor_exit_left.has(key) and not _anim_actor_exit_right.has(key):
				previous[key] = _actor_layout_rect(index)
				previous_facing[key] = actor_views[index].flip_h
	if is_node_ready(): _prepare_background(state)
	_state = state.duplicate(true)
	_move_from.clear()
	var next_actors: Array = state.get("actors", [])
	for index in mini(next_actors.size(), actor_views.size()):
		var key: String = next_actors[index]
		if previous.has(key):
			var target := _target_actor_rect(index, next_actors.size())
			if not previous[key].is_equal_approx(target): _move_from[key] = previous[key]
	_effect_time = 0.0
	_anim_screen_shake = state.get("anim_screen_shake", false) and state.get("type") == "line"
	_anim_actor_shake = state.get("anim_actor_shake", []).duplicate() if state.get("type") == "line" else []
	_anim_actor_flip = state.get("anim_actor_flip", []).duplicate() if state.get("type") == "line" else []
	_actor_mirror = state.get("actor_mirror", []).duplicate()
	for index in mini(next_actors.size(), actor_views.size()):
		var key: String = next_actors[index]
		var target_facing := _actor_mirror.has(key) or index == 0
		if _move_from.has(key) and previous_facing.has(key) and previous_facing[key] != target_facing and not _anim_actor_flip.has(key):
			_anim_actor_flip.append(key)
	_anim_actor_exit_left = state.get("anim_actor_exit_left", []).duplicate() if state.get("type") == "line" else []
	_anim_actor_exit_right = state.get("anim_actor_exit_right", []).duplicate() if state.get("type") == "line" else []
	if not is_node_ready():
		return
	set_process(_anim_screen_shake or not _anim_actor_shake.is_empty() or not _anim_actor_flip.is_empty() or not _anim_actor_exit_left.is_empty() or not _anim_actor_exit_right.is_empty() or not _move_from.is_empty() or _framing_transition or _background_fade)
	if state.is_empty():
		_layout()
		return
	var visible_actors: Array = state.get("actors", [])
	for index in actor_views.size():
		var actor: TextureRect = actor_views[index]
		actor.visible = index < visible_actors.size()
		if actor.visible:
			var key: String = visible_actors[index]
			actor.texture = _actors.get(key)
			var active: String = state.get("speaker_actor", "")
			actor.modulate = Color.WHITE if active.is_empty() or active == key else Color(0.53, 0.57, 0.64)
	speaker.text = state.get("speaker", "")
	speaker.visible = not speaker.text.is_empty() and speaker.text != "旁白"
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

func _texture(parent: Node = null) -> TextureRect:
	var view := TextureRect.new()
	view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	view.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	(parent if parent != null else self).add_child(view)
	return view

func _process(delta: float) -> void:
	_effect_time += delta
	_apply_effects()
	var exit_end := ACTOR_EXIT_DELAY + ACTOR_EXIT_DURATION if not _anim_actor_exit_left.is_empty() or not _anim_actor_exit_right.is_empty() else 0.0
	if _effect_time >= maxf(maxf(SCREEN_SHAKE_DURATION, ACTOR_SHAKE_DURATION), maxf(maxf(ACTOR_FLIP_DURATION, exit_end), maxf(ACTOR_MOVE_DURATION, BACKGROUND_TRANSITION_DURATION))):
		set_process(false)

func _apply_effects() -> void:
	var unit := minf(size.x / 1600.0, size.y / 900.0)
	var screen_strength := maxf(0.0, 1.0 - _effect_time / SCREEN_SHAKE_DURATION) if _anim_screen_shake else 0.0
	_stage.position = Vector2(sin(_effect_time * TAU * 8.0), sin(_effect_time * TAU * 6.0)) * 10.0 * unit * screen_strength
	# Overscan only while shaking so the moving image never exposes an edge.
	var margin := 14.0 * unit * screen_strength
	background.offset_left = -margin
	background.offset_top = -margin
	background.offset_right = margin
	background.offset_bottom = margin
	for backdrop in [_previous_background]:
		backdrop.offset_left = -margin
		backdrop.offset_top = -margin
		backdrop.offset_right = margin
		backdrop.offset_bottom = margin
	_apply_background_transition()
	var actor_strength := maxf(0.0, 1.0 - _effect_time / ACTOR_SHAKE_DURATION)
	var actors: Array = _state.get("actors", [])
	for index in actor_views.size():
		var actor := actor_views[index]
		var key: String = actors[index] if index < actors.size() else ""
		var offset := Vector2.ZERO
		if _anim_actor_shake.has(key):
			offset = Vector2(sin(_effect_time * TAU * 8.0), sin(_effect_time * TAU * 6.0) * 0.35) * 16.0 * unit * actor_strength
		var flip_progress := clampf(_effect_time / ACTOR_FLIP_DURATION, 0.0, 1.0)
		actor.flip_h = _actor_mirror.has(key) or (not actors.is_empty() and index == 0)
		actor.scale = Vector2.ONE
		if _anim_actor_flip.has(key):
			# Turn through a narrow profile, then open into the authored facing.
			actor.scale.x = maxf(0.001, absf(cos(PI * flip_progress)))
			if flip_progress < 0.5: actor.flip_h = not actor.flip_h
		var exiting := _anim_actor_exit_left.has(key) or _anim_actor_exit_right.has(key)
		var exit_direction := -1.0 if _anim_actor_exit_left.has(key) else 1.0
		var exit_progress := clampf((_effect_time - ACTOR_EXIT_DELAY) / ACTOR_EXIT_DURATION, 0.0, 1.0) if exiting else 0.0
		var layout := _actor_layout_rect(index)
		actor.size = layout.size * size
		actor.pivot_offset = actor.size * 0.5
		actor.position = layout.position * size + offset + Vector2(exit_direction * size.x * 1.1 * exit_progress * exit_progress, 0.0)
		actor.modulate.a = 1.0 - exit_progress
		actor.visible = index < actors.size() and exit_progress < 1.0

func _prepare_background(state: Dictionary) -> void:
	var next: Texture2D = _backgrounds.get(state.get("background", ""))
	var previous_base := _background_base
	var previous_region := _background_region
	var previous_fade: bool = _background_fade and _previous_background.visible
	var previous_alpha: float = background.modulate.a
	_framing_transition = false
	_background_fade = false
	if next == null:
		_background_base = null
		background.texture = null
		background.modulate.a = 1.0
		_previous_background.visible = false
		return
	_background_base = next
	var full := Rect2(Vector2.ZERO, next.get_size())
	var target := Rect2(Vector2.ZERO, next.get_size() * Vector2(0.6, 1.0)) if state.get("framing", "wide") == "left_close" else full
	_background_region_to = target
	if previous_base == next and previous_base != null:
		_background_region_from = previous_region
		_background_region = previous_region
		_framing_transition = not previous_region.is_equal_approx(target)
		if previous_fade:
			_background_fade = true
			_fade_start = previous_alpha
		else:
			_previous_background.visible = false
			background.modulate.a = 1.0
	else:
		if previous_base != null and background.texture != null:
			# Freeze the old framing; it must not share a mutable AtlasTexture.
			var old_crop := AtlasTexture.new()
			old_crop.atlas = previous_base
			old_crop.region = previous_region
			_previous_background.texture = old_crop
			_previous_background.visible = true
			_background_fade = true
			_fade_start = 0.0
		else:
			_previous_background.visible = false
			background.modulate.a = 1.0
		_background_region_from = target
		_background_region = target
	_background_crop = AtlasTexture.new()
	_background_crop.atlas = next
	_background_crop.region = _background_region
	background.texture = next if _background_region.is_equal_approx(full) and not _framing_transition else _background_crop
	if _background_fade: background.modulate.a = _fade_start

func _apply_background_transition() -> void:
	if _background_base == null: return
	var progress := clampf(_effect_time / BACKGROUND_TRANSITION_DURATION, 0.0, 1.0)
	progress = progress * progress * (3.0 - 2.0 * progress)
	if _framing_transition:
		_background_region = Rect2(_background_region_from.position.lerp(_background_region_to.position, progress), _background_region_from.size.lerp(_background_region_to.size, progress))
		_background_crop.region = _background_region
		if progress >= 1.0:
			_framing_transition = false
			var full := Rect2(Vector2.ZERO, _background_base.get_size())
			if _background_region.is_equal_approx(full): background.texture = _background_base
	if _background_fade:
		background.modulate.a = lerpf(_fade_start, 1.0, progress)
		if progress >= 1.0:
			_background_fade = false
			_previous_background.visible = false
			_previous_background.texture = null

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
	button.pressed.connect(func(): ui_sound_requested.emit("sfx_ui_click"))
	parent.add_child(button)
	return button

func _target_actor_rect(index: int, count: int) -> Rect2:
	if size.x <= 0.0 or size.y <= 0.0: return Rect2()
	var actor_height := size.y * 0.82
	var actor_width := minf(size.x * (0.58 if count == 1 else 0.46), actor_height * 1.1)
	var center_x: float = size.x * (0.5 if count == 1 else [0.31, 0.69][index])
	return Rect2(Vector2(center_x - actor_width * 0.5, size.y * 0.12) / size, Vector2(actor_width, actor_height) / size)

func _actor_layout_rect(index: int) -> Rect2:
	var actors: Array = _state.get("actors", [])
	var target := _target_actor_rect(index, actors.size())
	if index >= actors.size() or not _move_from.has(actors[index]): return target
	var start: Rect2 = _move_from[actors[index]]
	var progress := clampf(_effect_time / ACTOR_MOVE_DURATION, 0.0, 1.0)
	progress = progress * progress * (3.0 - 2.0 * progress)
	return Rect2(start.position.lerp(target.position, progress), start.size.lerp(target.size, progress))

func _layout() -> void:
	if not is_node_ready():
		return
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
	_apply_effects()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		ui_sound_requested.emit("sfx_ui_click")
		advance_requested.emit()
		accept_event()
