extends SceneTree
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func run() -> void:
	change_scene_to_file("res://devtools/story_test/story_workspace.tscn")
	await process_frame
	await process_frame
	var workspace = current_scene
	check(workspace.session.snapshot().id == "arrival", "Workspace loads sample")
	check(workspace.stage.actor_views[0].visible and not workspace.stage.actor_views[1].visible, "Single character appears")
	check(workspace.stage.actor_views[0].texture == workspace.SCOUT.poses[0], "Reuses battle appearance pose")
	workspace.continue_button.pressed.emit()
	check(workspace.stage.actor_views[1].visible, "Second character enters")
	check(workspace.stage.actor_views[1].modulate == Color.WHITE and workspace.stage.actor_views[0].modulate.r < 1, "Current speaker is highlighted")
	workspace.continue_button.pressed.emit()
	check(workspace.choices.get_child_count() == 2 and not workspace.continue_button.visible, "Choice UI requires selection")
	workspace.choices.get_child(0).pressed.emit()
	check(workspace.stage.background.texture == workspace.BACKGROUNDS.garden, "Background changes to supplied garden")
	check(not workspace.stage.actor_views[1].visible, "Second character exits")
	workspace.continue_button.pressed.emit()
	check(workspace.session.snapshot().id == "ridge_end" and not workspace.continue_button.visible, "First ending is shown")
	check(not workspace.stage.actor_views[0].visible and not workspace.stage.actor_views[1].visible, "Ending clears foreground actors")
	workspace._restart()
	check(workspace.session.snapshot().history.size() == 1 and workspace.continue_button.visible, "Replay clears transcript")
	workspace._advance()
	workspace._advance()
	workspace.choices.get_child(1).pressed.emit()
	workspace._advance()
	check(workspace.session.snapshot().id == "canal_end" and workspace.history.text.contains("穿过旧水渠"), "Second branch and transcript shown")
	workspace._restart()
	workspace._toggle_auto()
	workspace._process(100)
	workspace._process(100)
	check(workspace.session.snapshot().id == "route" and not workspace.auto_play, "Automatic playback stops at choice")
	var before: Dictionary = workspace.session.snapshot()
	workspace._skip()
	check(workspace.session.snapshot() == before, "Skip cannot select a branch")
	workspace._restart()
	workspace._toggle_auto()
	workspace._show_overlay(false)
	workspace._process(100)
	check(workspace.session.snapshot().id == "arrival", "Reading history pauses auto playback")
	workspace.modal.hide()
	workspace._skip()
	check(workspace.session.snapshot().id == "route" and not workspace.auto_play, "Skip stops at pending choice")
	workspace._choose(0)
	workspace._skip()
	check(workspace.session.snapshot().finished, "Skip stops at ending")
	var loop = preload("res://features/story/story_script.gd").new()
	loop.start = "loop"
	loop.nodes = {"loop": {"type": "line", "text": "Loop", "next": "loop"}}
	workspace.session.load_story(loop)
	workspace._skip()
	check(workspace.session.snapshot().history.size() == 2, "Skip detects graph cycle")
	var departed = weakref(workspace)
	change_scene_to_file("res://devtools/hub/developer_hub.tscn")
	await process_frame
	await process_frame
	check(departed.get_ref() == null, "Story workspace is released")
	check(current_scene.ENTRIES.size() == 5, "Hub exposes Story Test")
	print("Story workspace: %d failures" % failures)
	quit(1 if failures else 0)
