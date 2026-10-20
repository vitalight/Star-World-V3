extends Control
## Development entry point; contains no combat or asset-loading logic.

const WORKSPACES: Array[PackedScene] = [
	preload("res://devtools/blueprint/blueprint_workspace.tscn"),
	preload("res://devtools/art_test/art_workspace.tscn"),
	preload("res://devtools/logic_test/logic_workspace.tscn"),
	preload("res://devtools/game_test/game_workspace.tscn"),
]


func _ready() -> void:
	for workspace_scene in WORKSPACES:
		%Workspaces.add_child(workspace_scene.instantiate())
