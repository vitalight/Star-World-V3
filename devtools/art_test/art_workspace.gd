extends Control

const ACTOR = preload("res://features/actor_view/actor_view.gd")
const EFFECT = preload("res://features/effects/effect_view.gd")
const FIELD = preload("res://features/battlefield_view/battlefield_view.gd")
const HUD = preload("res://features/battle_hud/battle_hud.gd")
const ALLY = preload("res://content/characters/character_001/frames.tres")
const ENEMY = preload("res://content/characters/character_002/frames.tres")
const SPARK = preload("res://content/effects/effect_001/texture.tres")
const TERRAIN = preload("res://content/terrains/terrain_001/atlas.png")
@export_enum("Art Test", "Character", "Effect", "Battle Scene") var page: int = 0
var actors: Array[Node2D] = []
var status: Label

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color("111a27")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for edge in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + edge, 30)
	add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	margin.add_child(box)
	var nav := HBoxContainer.new()
	box.add_child(nav)
	button(nav, "← 开发者首页", func(): get_tree().change_scene_to_file("res://devtools/hub/developer_hub.tscn"))
	if page > 0:
		button(nav, "Art Test 目录", func(): get_tree().change_scene_to_file("res://devtools/art_test/art_workspace.tscn"))
	label(box, "ART TEST / " + ["素材检视", "CHARACTER", "EFFECT", "BATTLE SCENE"][page], 32)
	label(box, "StarterContent · 表现与比例检查 · 模拟展示，不计算战斗", 18)
	match page:
		0: build_menu(box)
		1: build_characters(box)
		2: build_effects(box)
		3: build_battle(box)

func label(parent: Node, text: String, font_size: int = 20) -> Label:
	var item := Label.new()
	item.text = text
	item.add_theme_font_size_override("font_size", font_size)
	parent.add_child(item)
	return item

func button(parent: Node, text: String, callback: Callable) -> Button:
	var item := Button.new()
	item.text = text
	item.custom_minimum_size = Vector2(0, 44)
	item.add_theme_font_size_override("font_size", 18)
	item.pressed.connect(callback)
	parent.add_child(item)
	return item

func stage(parent: Node, height: float) -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size.y = height
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = Color("202d3e")
	style.border_color = Color("405775")
	style.set_border_width_all(1)
	panel.add_theme_stylebox_override("panel", style)
	parent.add_child(panel)
	var canvas := Control.new()
	canvas.clip_contents = true
	panel.add_child(canvas)
	return canvas

func build_menu(box: VBoxContainer) -> void:
	label(box, "选择一个独立展示场景", 23)
	var pages := ["Character — 我方 / 敌人 / 四个真实姿态", "Effect — 斩击贴图 / 可重复脉冲演示", "Battle Scene — 地形 / 单位 / 特效 / 静态 UI"]
	var files := ["character_preview", "effect_preview", "battle_preview"]
	for i in 3:
		var destination: String = "res://devtools/art_test/" + files[i] + ".tscn"
		button(box, pages[i], func(): get_tree().change_scene_to_file(destination))
	label(box, "已检查图集：2 张我方、2 张敌方、2 张特效、1 张地形。", 18)
	label(box, "重要：角色是独立姿态，特效是大小变体；原素材没有连续动画序列。", 18)
	label(box, "展示中的循环是待机 / 攻击姿态切换和缩放淡出，不冒充原始动画。", 18)
	var canvas := stage(box, 220)
	add_actor(canvas, ALLY, Vector2(260, 140), 0.6)
	add_actor(canvas, ENEMY, Vector2(560, 140), 0.6)
	add_effect(canvas, Vector2(860, 130), 0.65)

func add_actor(parent: Node, frames: SpriteFrames, at: Vector2, factor: float) -> Node2D:
	var actor := Node2D.new()
	actor.set_script(ACTOR)
	actor.frames = frames
	actor.display_scale = factor
	actor.position = at
	parent.add_child(actor)
	actors.append(actor)
	return actor

func add_effect(parent: Node, at: Vector2, factor: float) -> Node2D:
	var effect := Node2D.new()
	effect.set_script(EFFECT)
	effect.texture = SPARK
	effect.display_scale = factor
	effect.position = at
	parent.add_child(effect)
	return effect

func build_characters(box: VBoxContainer) -> void:
	label(box, "character_001 · 我方赤刃       /       character_002 · 敌方斥候", 22)
	var controls := HBoxContainer.new()
	box.add_child(controls)
	var choices := OptionButton.new()
	var names := ["front_preview", "back_preview", "front_idle", "back_idle", "front_attack", "back_attack"]
	for value in ["正面姿态循环（2 姿态）", "背面姿态循环（2 姿态）", "正面待机（静态）", "背面待机（静态）", "正面攻击（静态）", "背面攻击（静态）"]:
		choices.add_item(value)
	controls.add_child(choices)
	choices.item_selected.connect(func(index: int):
		for actor in actors: actor.show_animation(names[index])
		status.text = "当前动作：" + choices.get_item_text(index))
	button(controls, "播放", func():
		for actor in actors: actor.set_playing(true))
	button(controls, "暂停", func():
		for actor in actors: actor.set_playing(false))
	button(controls, "单步", func():
		for actor in actors: actor.step())
	status = label(box, "当前动作：正面姿态循环（2 姿态）", 18)
	var canvas := stage(box, 330)
	var ally := add_actor(canvas, ALLY, Vector2(330, 220), 1.05)
	var enemy := add_actor(canvas, ENEMY, Vector2(890, 220), 1.05)
	var inspect := HBoxContainer.new()
	box.add_child(inspect)
	button(inspect, "我方独查", func(): ally.visible = true; enemy.visible = false)
	button(inspect, "敌方独查", func(): ally.visible = false; enemy.visible = true)
	button(inspect, "双方对照", func(): ally.visible = true; enemy.visible = true)
	label(box, "图集第 1 行：正面待机 / 背面待机 / 正面攻击 / 背面攻击。无行走、受击、死亡帧。", 17)

func build_effects(box: VBoxContainer) -> void:
	label(box, "effect_001 · 金色斩击 / effect-atlas-01 第 1 格", 22)
	var canvas := stage(box, 330)
	var effect := add_effect(canvas, Vector2(600, 210), 1.15)
	var controls := HBoxContainer.new()
	box.add_child(controls)
	button(controls, "重播", func(): effect.replay())
	var loop := CheckButton.new()
	loop.text = "循环播放"
	loop.button_pressed = true
	loop.toggled.connect(func(enabled: bool): effect.repeat = enabled; effect.replay())
	controls.add_child(loop)
	button(controls, "静态原图", func(): effect.set_process(false); effect.sprite.scale = Vector2.ONE * 1.15; effect.sprite.modulate.a = 1.0)
	button(controls, "脉冲演示", func(): effect.set_process(true); effect.replay())
	label(box, "静态原图可检查边缘；脉冲由程序缩放与淡出构成，不是图集帧动画。", 18)
	label(box, "素材含斩击、弹体、治疗、命中、增益、护盾、爆炸、冰刺的大小变体。", 18)

func build_battle(box: VBoxContainer) -> void:
	label(box, "scene_001 · 荒原哨站 / terrain_001 · 荒原图集", 22)
	var canvas := stage(box, 470)
	var field := Node2D.new()
	field.set_script(FIELD)
	field.atlas = TERRAIN
	field.position = Vector2(90, 35)
	canvas.add_child(field)
	# Unit positions are feet-aligned to the same ground grid. Draw order follows depth.
	add_actor(canvas, ALLY, Vector2(400, 160), 0.48)
	add_actor(canvas, ENEMY, Vector2(750, 248), 0.48)
	add_actor(canvas, ALLY, Vector2(575, 335), 0.48)
	add_effect(canvas, Vector2(672, 235), 0.5)
	var hud := PanelContainer.new()
	hud.set_script(HUD)
	hud.position = Vector2(24, 12)
	canvas.add_child(hud)
	label(box, "我方 × 2 · 敌方 × 1 · 示例斩击 · 静态 LIFE / WAVE / COST", 18)
	label(box, "中心浅色道路与草地部署区仅用于画面检查；所有单位原地展示，无战斗规则。", 18)
