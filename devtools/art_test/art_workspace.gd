extends Control

const ACTOR = preload("res://features/actor_view/actor_view.gd")
const EFFECT = preload("res://features/effects/effect_view.gd")
const UI = preload("res://devtools/ui/workspace_style.gd")
const CATALOG = preload("res://devtools/art_test/asset_catalog.gd")
const TAB_NAMES = ["Character", "Effect", "Animation", "Battle", "Skill"]
const PREVIEW_SCALE = 0.44
const PREVIEW_CENTER = Vector2(104, 74)
@export_enum("Character", "Effect", "Animation", "Battle", "Skill") var page: int = 0
var tabs: TabContainer
var character_scroll: ScrollContainer
var character_columns: HBoxContainer
var effect_grid: HFlowContainer
var skill_grid: HFlowContainer
var animation_actors: Array[Node2D] = []
var animation_effects: Array[Node2D] = []
var battle_stage: Control
var animation_playing := true

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var box := UI.shell(self, "Art Test", Color("7dc6ba"))
	tabs = TabContainer.new()
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tabs.add_theme_font_size_override("font_size", 20)
	box.add_child(tabs)
	for title in TAB_NAMES:
		var panel := VBoxContainer.new()
		panel.name = title
		panel.add_theme_constant_override("separation", 10)
		tabs.add_child(panel)
	build_characters(tabs.get_child(0))
	build_effects(tabs.get_child(1))
	build_animations(tabs.get_child(2))
	build_battle(tabs.get_child(3))
	build_skills(tabs.get_child(4))
	tabs.current_tab = page
	tabs.tab_changed.connect(_tab_changed)
	_tab_changed(page)

func _tab_changed(index: int) -> void:
	page = index
	for i in tabs.get_child_count():
		tabs.get_child(i).process_mode = Node.PROCESS_MODE_INHERIT if i == index else Node.PROCESS_MODE_DISABLED
	_sync_playback()

func _sync_playback() -> void:
	for actor in animation_actors:
		actor.set_playing(page == 2 and animation_playing)
	for effect in animation_effects:
		effect.set_process(page == 2 and animation_playing)
	if battle_stage:
		battle_stage.set_active(page == 3)

func set_animation_playing(enabled: bool) -> void:
	animation_playing = enabled
	_sync_playback()

func replay_animations() -> void:
	for actor in animation_actors:
		actor.sprite.stop()
		actor.sprite.play()
	for effect in animation_effects:
		effect.replay()
	set_animation_playing(true)

func label(parent: Node, text: String, font_size: int = 18) -> Label:
	var item := Label.new()
	item.text = text
	item.add_theme_font_size_override("font_size", font_size)
	parent.add_child(item)
	return item

func button(parent: Node, text: String, callback: Callable) -> Button:
	var item := Button.new()
	item.text = text
	item.custom_minimum_size.y = 40
	item.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	item.pressed.connect(callback)
	parent.add_child(item)
	return item

func scroll_body(parent: Node, horizontal: bool = false) -> VBoxContainer:
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO if horizontal else ScrollContainer.SCROLL_MODE_DISABLED
	parent.add_child(scroll)
	var body := VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 12)
	scroll.add_child(body)
	return body

func card(parent: Node) -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size.x = 208
	parent.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 4)
	panel.add_child(column)
	return column

func image_cell(parent: Node, texture: Texture2D) -> void:
	var image := TextureRect.new()
	image.custom_minimum_size = Vector2(200, 114)
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.texture = texture
	parent.add_child(image)
	image_border(image, texture)

func image_border(parent: Control, texture: Texture2D, animated: bool = false) -> void:
	# Outline the full source slice, including transparent margins, rather than the card.
	var border := Control.new()
	border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	border.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	border.z_index = 1
	parent.add_child(border)
	border.draw.connect(func():
		var source_size := texture.get_size()
		var factor := PREVIEW_SCALE if animated else minf(border.size.x / source_size.x, border.size.y / source_size.y)
		var extent := source_size * factor
		var center := PREVIEW_CENTER if animated else border.size / 2.0
		border.draw_rect(Rect2(center - extent / 2.0, extent).grow(-1.0), Color("8aacc5"), false, 2.0))
	border.resized.connect(border.queue_redraw)

func build_characters(box: VBoxContainer) -> void:
	label(box, "16 个角色 · 每列四姿态 · 水平滚动浏览")
	character_scroll = ScrollContainer.new()
	character_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(character_scroll)
	character_columns = HBoxContainer.new()
	character_columns.add_theme_constant_override("separation", 12)
	character_scroll.add_child(character_columns)
	for entry in CATALOG.characters():
		var column := card(character_columns)
		label(column, entry.source, 16)
		label(column, "角色行 %d" % (entry.row + 1), 16)
		for i in 4:
			label(column, CATALOG.POSES[i], 16)
			image_cell(column, entry.poses[i])

func build_effects(box: VBoxContainer) -> void:
	label(box, "32 张静态素材 · 包括大小变体")
	var body := scroll_body(box)
	effect_grid = HFlowContainer.new()
	body.add_child(effect_grid)
	for entry in CATALOG.effects():
		var column := card(effect_grid)
		label(column, entry.source, 16)
		label(column, "行 %d / 列 %d" % [entry.row + 1, entry.column + 1], 16)
		image_cell(column, entry.texture)

func build_animations(box: VBoxContainer) -> void:
	var controls := HBoxContainer.new()
	box.add_child(controls)
	button(controls, "播放", set_animation_playing.bind(true))
	button(controls, "暂停", set_animation_playing.bind(false))
	button(controls, "重播", replay_animations)
	var body := scroll_body(box)
	label(body, "角色 · 姿态循环（2 FPS，待机 / 攻击交替）")
	var actors_grid := HFlowContainer.new()
	body.add_child(actors_grid)
	for entry in CATALOG.characters():
		for back in [false, true]:
			var column := card(actors_grid)
			label(column, entry.source, 16)
			label(column, "行 %d · %s" % [entry.row + 1, "背面" if back else "正面"], 16)
			var canvas := preview_cell(column, entry.poses[0])
			var actor := Node2D.new()
			actor.set_script(ACTOR)
			actor.frames = CATALOG.frames(entry.poses, back)
			actor.animation = &"default"
			actor.display_scale = PREVIEW_SCALE
			actor.position = PREVIEW_CENTER
			canvas.add_child(actor)
			animation_actors.append(actor)
	label(body, "特效 · 程序脉冲（缩放 / 淡出，非连续帧动画）")
	var effects_grid := HFlowContainer.new()
	body.add_child(effects_grid)
	for entry in CATALOG.effects():
		var column := card(effects_grid)
		label(column, entry.source, 16)
		label(column, "行 %d / 列 %d" % [entry.row + 1, entry.column + 1], 16)
		var canvas := preview_cell(column, entry.texture)
		var effect := Node2D.new()
		effect.set_script(EFFECT)
		effect.texture = entry.texture
		effect.display_scale = PREVIEW_SCALE
		effect.position = PREVIEW_CENTER
		canvas.add_child(effect)
		animation_effects.append(effect)

func preview_cell(parent: Node, texture: Texture2D) -> Control:
	var canvas := Control.new()
	canvas.custom_minimum_size = Vector2(208, 148)
	canvas.clip_contents = true
	parent.add_child(canvas)
	image_border(canvas, texture, true)
	return canvas

func build_battle(box: VBoxContainer) -> void:
	battle_stage = AspectRatioContainer.new()
	battle_stage.set_script(preload("res://devtools/art_test/battle_stage.gd"))
	battle_stage.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(battle_stage)

func build_skills(box: VBoxContainer) -> void:
	label(box, "技能图标 · 16 张静态素材")
	var body := scroll_body(box)
	label(body, "skill-atlas-01.png · 4 × 4", 18)
	skill_grid = HFlowContainer.new()
	skill_grid.add_theme_constant_override("h_separation", 12)
	skill_grid.add_theme_constant_override("v_separation", 12)
	body.add_child(skill_grid)
	for entry in CATALOG.skills():
		var column := card(skill_grid)
		label(column, entry.name, 18)
		image_cell(column, entry.texture)
		label(column, "行 %d / 列 %d" % [entry.row + 1, entry.column + 1], 15)
