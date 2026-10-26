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
	check(workspace.source_picker.item_count == 4 and workspace.source_picker.get_item_metadata(0) == ["scene_002", "before"], "Workspace contains only formal stories and defaults to 1-1")
	check(workspace.session.snapshot().text.contains("突然停电"), "Workspace opens formal blackout scene")
	check(not workspace.stage.actor_views[0].visible and not workspace.stage.actor_views[1].visible, "Opening has no foreground actors")
	workspace.continue_button.pressed.emit()
	check(workspace.stage.actor_views[0].visible and not workspace.stage.actor_views[1].visible and workspace.speaker.text == "大星", "Protagonist enters alone")
	workspace.continue_button.pressed.emit()
	check(not workspace.stage.background.texture is AtlasTexture and not workspace.stage.actor_views[0].visible, "Portal reveal restores wide framing without actors")
	workspace.continue_button.pressed.emit()
	check(workspace.session.snapshot().actors == ["character_012"] and not workspace.speaker.visible, "Cat first appears alone at curious look")
	workspace._skip()
	check(workspace.session.snapshot().finished and not workspace.continue_button.visible, "Skip reaches formal story ending")
	check(not workspace.stage.actor_views[0].visible and not workspace.stage.actor_views[1].visible, "Ending clears foreground actors")
	workspace._restart()
	check(workspace.session.snapshot().history.size() == 1 and workspace.continue_button.visible, "Replay clears transcript")
	workspace.source_picker.select(1)
	workspace._load_source(1)
	for step in 4: workspace._advance()
	check(workspace.stage.actor_views[0].visible and workspace.stage.actor_views[1].visible, "Formal conversation shows both characters")
	check(workspace.stage.actor_views[1].modulate == Color.WHITE and workspace.stage.actor_views[0].modulate.r < 1, "Current speaker is highlighted")
	check(workspace.history.text.contains("小黄") and not workspace.history.text.contains("旁白："), "Formal story transcript omits narrator label")
	workspace._restart()
	workspace._toggle_auto()
	workspace._process(100)
	check(workspace.session.snapshot().id == "line_1", "Automatic playback advances formal story")
	workspace._skip()
	check(workspace.session.snapshot().finished and not workspace.auto_play, "Skip stops playback at formal ending")
	workspace._restart()
	workspace._toggle_auto()
	workspace._show_overlay(false)
	workspace._process(100)
	check(workspace.session.snapshot().id == "line_0", "Reading history pauses auto playback")
	workspace.modal.hide()
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
