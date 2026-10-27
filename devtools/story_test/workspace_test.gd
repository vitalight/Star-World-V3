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
	check(workspace.source_picker.item_count == 5 and workspace.source_picker.get_item_metadata(0) == ["scene_0101A", "story"], "Workspace contains only formal stories and defaults to 1-1")
	check(workspace.session.snapshot().text.contains("晚上七点"), "Workspace opens formal blackout scene")
	check(not workspace.stage.actor_views[0].visible and not workspace.stage.actor_views[1].visible, "Opening has no foreground actors")
	check(workspace.back_button.disabled, "Back is disabled at the beginning")
	workspace.continue_button.pressed.emit()
	workspace.continue_button.pressed.emit()
	check(workspace.stage.actor_views[0].visible and not workspace.stage.actor_views[1].visible and workspace.speaker.text == "大星", "Protagonist enters alone")
	workspace._toggle_auto()
	workspace.back_button.pressed.emit()
	check(workspace.session.snapshot().id == "line_1" and workspace.session.snapshot().history.size() == 2 and not workspace.auto_play, "Back restores the prior dialogue and stops auto play")
	workspace.back_button.pressed.emit()
	check(workspace.session.snapshot().id == "line_0" and workspace.back_button.disabled, "Back stops at the first dialogue")
	workspace._advance()
	workspace._advance()
	var before_reload: Dictionary = workspace.session.snapshot()
	var reload_buttons: Array = workspace.toolbar.find_children("*", "Button", true, false).filter(func(button): return button.text == "重新加载")
	check(reload_buttons.size() == 1, "Reload button is available")
	if not reload_buttons.is_empty(): reload_buttons[0].pressed.emit()
	check(workspace.session.snapshot().id == before_reload.id and workspace.session.snapshot().history.size() == before_reload.history.size(), "Reload restores dialogue position and rebuilds history")
	check(workspace.dialogue.text == before_reload.text, "Reload displays current dialogue")
	workspace.back_button.pressed.emit()
	check(workspace.session.snapshot().id == "line_1", "Back works after reload")
	workspace._advance()
	while workspace.session.snapshot().get("framing") != "wide": workspace._advance()
	workspace.stage._process(workspace.stage.BACKGROUND_TRANSITION_DURATION)
	check(not workspace.stage.background.texture is AtlasTexture and not workspace.stage.actor_views[0].visible, "Portal reveal restores wide framing without actors")
	while workspace.session.snapshot().get("actors") != ["character_012"]: workspace._advance()
	check(not workspace.speaker.visible, "Cat action appears alone without narrator label")
	workspace._skip()
	check(workspace.session.snapshot().finished and not workspace.continue_button.visible, "Skip reaches formal story ending")
	workspace.back_button.pressed.emit()
	check(not workspace.session.snapshot().finished and workspace.continue_button.visible, "Back from ending returns to last dialogue")
	workspace._skip()
	check(not workspace.stage.actor_views[0].visible and not workspace.stage.actor_views[1].visible, "Ending clears foreground actors")
	workspace._restart()
	check(workspace.session.snapshot().history.size() == 1 and workspace.continue_button.visible, "Replay clears transcript")
	workspace.source_picker.select(1)
	workspace._load_source(1)
	check(workspace.session.snapshot().id == "line_0", "Changing story starts at the beginning")
	for index in range(20):
		if workspace.session.snapshot().get("actors", []).size() == 2 and not workspace.session.snapshot().get("speaker_actor", "").is_empty(): break
		workspace._advance()
	check(workspace.stage.actor_views[0].visible and workspace.stage.actor_views[1].visible, "Formal conversation shows both characters")
	check(workspace.stage.actor_views.any(func(actor): return actor.modulate == Color.WHITE) and workspace.stage.actor_views.any(func(actor): return actor.modulate.r < 1), "Current speaker is highlighted")
	check(not workspace.history.text.contains("旁白："), "Formal story transcript omits narrator label")
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
	var short_story = preload("res://features/story/story_script.gd").new()
	short_story.start = "line_0"
	short_story.nodes = {"line_0": {"type": "line", "text": "New first", "next": "line_1"}, "line_1": {"type": "line", "text": "New last", "next": "end"}, "end": {"type": "end", "text": ""}}
	workspace.session.load_story(short_story)
	workspace._restore_position(short_story, 20, false)
	check(workspace.session.snapshot().id == "line_1" and workspace.session.snapshot().history.size() == 2, "Shortened story restores to last available dialogue")
	workspace.session.load_story(short_story)
	workspace._restore_position(short_story, 20, true)
	check(workspace.session.snapshot().finished, "Reload preserves ending when story was finished")
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
