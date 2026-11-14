extends Control

const ACTOR = preload("res://features/actor_view/actor_view.gd")
const EFFECT = preload("res://features/effects/effect_view.gd")
const UI = preload("res://devtools/ui/workspace_style.gd")
const CATALOG = preload("res://devtools/art_test/asset_catalog.gd")
const TAB_NAMES = ["Character", "Enemy", "Effect", "Animation", "Battle", "Skill"]
enum Page { CHARACTER, ENEMY, EFFECT, ANIMATION, BATTLE, SKILL }
const PREVIEW_CENTER = Vector2(104, 74)
@export_enum("Character", "Enemy", "Effect", "Animation", "Battle", "Skill") var page: int = 0
var tabs: TabContainer
var character_scroll: ScrollContainer
var character_columns: HBoxContainer
var enemy_scroll: ScrollContainer
var enemy_columns: HBoxContainer
var effect_grid: HFlowContainer
var skill_grid: HFlowContainer
var animation_actors: Array[Node2D] = []
var animation_effects: Array[Node2D] = []
var battle_stage: Control
var animation_playing := true
var game_catalog
var actor_entries := {}
var built_pages := {}

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
	tabs.current_tab = page
	tabs.tab_changed.connect(_tab_changed)
	_tab_changed(page)

func _tab_changed(index: int) -> void:
	page = index
	for i in tabs.get_child_count():
		tabs.get_child(i).process_mode = Node.PROCESS_MODE_INHERIT if i == index else Node.PROCESS_MODE_DISABLED
	_build_page(index)
	_sync_playback()

func _build_page(index: int) -> void:
	if built_pages.has(index): return
	built_pages[index] = true
	var box: VBoxContainer = tabs.get_child(index)
	match index:
		Page.CHARACTER: build_characters(box, "character")
		Page.ENEMY: build_characters(box, "enemy")
		Page.EFFECT: build_effects(box)
		Page.ANIMATION: build_animations(box)
		Page.BATTLE: build_battle(box)
		Page.SKILL: build_skills(box)

func _game_catalog():
	if game_catalog == null:
		game_catalog = CATALOG.GameCatalog.new()
		game_catalog.reload()
	return game_catalog

func _actor_entries(kind: String) -> Array:
	if not actor_entries.has(kind):
		actor_entries[kind] = CATALOG.characters(_game_catalog(), kind)
	return actor_entries[kind]

func _sync_playback() -> void:
	for actor in animation_actors:
		actor.set_playing(page == Page.ANIMATION and animation_playing)
	for effect in animation_effects:
		effect.set_process(page == Page.ANIMATION and animation_playing)
	if battle_stage:
		battle_stage.set_active(page == Page.BATTLE)

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
		var factor := minf(190.0 / source_size.x, 134.0 / source_size.y) if animated else minf(border.size.x / source_size.x, border.size.y / source_size.y)
		var extent := source_size * factor
		var center := PREVIEW_CENTER if animated else border.size / 2.0
		border.draw_rect(Rect2(center - extent / 2.0, extent).grow(-1.0), Color("8aacc5"), false, 2.0))
	border.resized.connect(border.queue_redraw)

func build_characters(box: VBoxContainer, kind: String) -> void:
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(scroll)
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 12)
	scroll.add_child(columns)
	if kind == "character":
		character_scroll = scroll
		character_columns = columns
	else:
		enemy_scroll = scroll
		enemy_columns = columns
	for entry in _actor_entries(kind):
		var column := card(columns)
		label(column, entry.name, 18)
		label(column, entry.id if not entry.id.is_empty() else "未注册", 16)
		for action in ["attack", "move"]:
			if entry[action].is_empty(): continue
			for i in entry[action].size():
				label(column, "%s %d" % ["攻击" if action == "attack" else "移动", i + 1], 16)
				image_cell(column, entry[action][i])

func build_effects(box: VBoxContainer) -> void:
	label(box, "战斗特效")
	var body := scroll_body(box)
	effect_grid = HFlowContainer.new()
	body.add_child(effect_grid)
	for entry in CATALOG.effects():
		var column := card(effect_grid)
		label(column, entry.name, 16)
		image_cell(column, entry.texture)

func build_animations(box: VBoxContainer) -> void:
	var controls := HBoxContainer.new()
	box.add_child(controls)
	button(controls, "播放", set_animation_playing.bind(true))
	button(controls, "暂停", set_animation_playing.bind(false))
	button(controls, "重播", replay_animations)
	var body := scroll_body(box)
	label(body, "角色与敌人 · 动作循环")
	var actors_grid := HFlowContainer.new()
	body.add_child(actors_grid)
	for entry in _actor_entries("character") + _actor_entries("enemy"):
		for action in ["attack", "move"]:
			if entry[action].is_empty(): continue
			var column := card(actors_grid)
			label(column, "%s · %s" % [entry.name, "攻击" if action == "attack" else "移动"], 16)
			var texture: Texture2D = entry[action][0]
			var canvas := preview_cell(column, texture)
			var actor := Node2D.new()
			actor.set_script(ACTOR)
			actor.frames = CATALOG.frames(entry[action], action)
			actor.animation = &"default"
			actor.display_scale = minf(190.0 / texture.get_width(), 134.0 / texture.get_height())
			actor.position = PREVIEW_CENTER
			canvas.add_child(actor)
			animation_actors.append(actor)
	label(body, "特效 · 程序脉冲（缩放 / 淡出，非连续帧动画）")
	var effects_grid := HFlowContainer.new()
	body.add_child(effects_grid)
	for entry in CATALOG.effects():
		var column := card(effects_grid)
		label(column, entry.name, 16)
		var canvas := preview_cell(column, entry.texture)
		var effect := Node2D.new()
		effect.set_script(EFFECT)
		effect.texture = entry.texture
		effect.display_scale = minf(190.0 / entry.texture.get_width(), 134.0 / entry.texture.get_height())
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
	battle_stage.game_catalog = _game_catalog()
	battle_stage.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(battle_stage)

func build_skills(box: VBoxContainer) -> void:
	label(box, "技能图标")
	var body := scroll_body(box)
	skill_grid = HFlowContainer.new()
	skill_grid.add_theme_constant_override("h_separation", 12)
	skill_grid.add_theme_constant_override("v_separation", 12)
	body.add_child(skill_grid)
	for entry in CATALOG.skills(_game_catalog()):
		var column := card(skill_grid)
		label(column, entry.name, 18)
		image_cell(column, entry.texture)
