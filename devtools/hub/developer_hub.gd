extends Control
## Only navigation; departing scenes are freed by SceneTree.
const ENTRIES = [
	["Blueprint", "Compare two visual directions / A or B", "res://devtools/blueprint/blueprint_workspace.tscn"],
	["Art Test", "Character / Effect / Battle Scene", "res://devtools/art_test/art_workspace.tscn"],
	["Logic Test", "Deploy, fight, reset / geometric sandbox", "res://devtools/logic_test/logic_workspace.tscn"],
	["Game Test", "Pending integration / 待集成", "res://devtools/game_test/game_workspace.tscn"],
]
func _ready() -> void:
	RenderingServer.set_default_clear_color(Color("101b2a"))
	for entry in ENTRIES:
		var button = Button.new()
		button.text = entry[0] + "   —   " + entry[1]
		button.custom_minimum_size.y = 100
		button.pressed.connect(func(): get_tree().change_scene_to_file(entry[2]))
		%Workspaces.add_child(button)
