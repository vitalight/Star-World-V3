extends Control
const Game = preload("res://game/battle/battle_scene.tscn")
const DebugWindow = preload("res://devtools/game_test/debug_window.gd")
@export var operator_roster: Resource = preload("res://content/data/game_test_roster.tres")
var game: Node3D
var debug_window: PanelContainer

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	game = Game.instantiate()
	game.operator_roster = operator_roster
	add_child(game)
	game.exit_requested.connect(_return_to_hub)
	var layer := CanvasLayer.new()
	layer.layer = 20
	add_child(layer)
	var overlay := Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(overlay)
	debug_window = DebugWindow.new()
	debug_window.game = game
	overlay.add_child(debug_window)
	debug_window.hide()
	var toggle := Button.new()
	toggle.text = "F3"
	toggle.custom_minimum_size = Vector2(42, 26)
	toggle.pressed.connect(_toggle_debug)
	overlay.add_child(toggle)
	toggle.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	toggle.offset_left = 18; toggle.offset_right = 60
	toggle.offset_top = -44; toggle.offset_bottom = -18

func _toggle_debug() -> void:
	debug_window.visible = not debug_window.visible
	debug_window.clamp_rect()
	if game.battle: game.refresh()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F3:
		_toggle_debug()
		get_viewport().set_input_as_handled()

func _return_to_hub() -> void:
	get_tree().change_scene_to_file("res://devtools/hub/developer_hub.tscn")
