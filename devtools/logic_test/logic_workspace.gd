extends Control

const Battle = preload("res://features/battle/battle.gd")
const TestConfig = preload("res://devtools/logic_test/test_config.gd")
const Canvas = preload("res://devtools/logic_test/battle_canvas.gd")
var battle: RefCounted
var canvas: Control
var status: Label
var start_button: Button
var hint: Label

func _ready() -> void:
	battle = Battle.new(TestConfig.create())
	var margin = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 22)
	add_child(margin)
	var column = VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	margin.add_child(column)
	var header = HBoxContainer.new()
	column.add_child(header)
	var title = Label.new()
	title.text = "LOGIC TEST / Geometry battle sandbox"
	title.add_theme_font_size_override("font_size", 24)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var back = Button.new()
	back.text = "Back to hub"
	back.pressed.connect(func(): get_tree().change_scene_to_file("res://devtools/hub/developer_hub.tscn"))
	header.add_child(back)
	var actions = HBoxContainer.new()
	column.add_child(actions)
	start_button = Button.new()
	start_button.text = "Start wave"
	start_button.pressed.connect(func(): battle.start(); _refresh())
	actions.add_child(start_button)
	var reset_button = Button.new()
	reset_button.text = "Reset"
	reset_button.pressed.connect(_reset)
	actions.add_child(reset_button)
	status = Label.new()
	status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.add_child(status)
	hint = Label.new()
	hint.text = "Click numbered squares to deploy. Deploy all four to win; leave empty to test defeat."
	column.add_child(hint)
	canvas = Canvas.new()
	canvas.config = TestConfig.create()
	canvas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	canvas.slot_clicked.connect(_deploy)
	column.add_child(canvas)
	var legend = Label.new()
	legend.text = "Cyan squares: allies  |  Coral circles: enemies  |  Rings: attack range  |  Green bars: HP\nOne fixed wave: 8 enemies, base life 3. Placement is allowed before and during battle."
	column.add_child(legend)
	_refresh()

func _process(delta: float) -> void:
	if battle == null:
		return
	battle.advance(delta)
	for flash in canvas.flashes:
		flash.ttl -= delta
	canvas.flashes = canvas.flashes.filter(func(flash): return flash.ttl > 0.0)
	for event in battle.take_events():
		if event.type == "attack":
			event.ttl = 0.14
			canvas.flashes.append(event)
	_refresh()

func _deploy(index: int) -> void:
	if battle.deploy(index):
		hint.text = "Deployed slot %d. Automatic attacks target the enemy closest to the base." % (index + 1)
	else:
		hint.text = "Cannot deploy: slot occupied or battle finished. Reset to try again."
	_refresh()

func _reset() -> void:
	battle.reset()
	canvas.flashes.clear()
	hint.text = "Reset complete. Click slots to deploy, then start the wave."
	_refresh()

func _refresh() -> void:
	var state = battle.snapshot()
	canvas.state = state
	start_button.disabled = state.phase != "ready"
	status.text = "  %s  |  Life %d  |  Remaining %d  |  Killed %d  |  Escaped %d" % [state.phase.to_upper(), state.life, state.remaining, state.killed, state.escaped]
	canvas.queue_redraw()
