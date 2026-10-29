extends SceneTree
const Workspace = preload("res://devtools/game_test/game_workspace.tscn")
var failures := 0

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://temp/balance_editor"))
	var request := FileAccess.open("res://temp/balance_editor/play_request.json", FileAccess.WRITE)
	request.store_string(JSON.stringify({"level":"scene_0102B", "time":Time.get_unix_time_from_system()}))
	request.close()
	var workspace = Workspace.instantiate()
	get_root().add_child.call_deferred(workspace)
	call_deferred("_verify", workspace)

func _verify(workspace: Control) -> void:
	await process_frame
	await process_frame
	if workspace.game.campaign_level != "scene_0102B":
		failures += 1
		push_error("Selected campaign level was not loaded")
	if workspace.game.battle == null:
		failures += 1
		push_error("Battle failed to load: " + str(workspace.game.validation_errors))
	var picker = workspace.debug_window.level_picker
	if picker.get_selected_metadata() != "scene_0102B":
		failures += 1
		push_error("Debug picker does not reflect selected level")
	if FileAccess.file_exists("res://temp/balance_editor/play_request.json"):
		failures += 1
		push_error("Play request was not consumed")
	print("BALANCE PLAY: ", failures, " failures")
	workspace.queue_free()
	quit(1 if failures else 0)
