extends SceneTree

const Scene = preload("res://game/tests/sample_battle_fixture.tscn")
const Player = preload("res://game/player/player_mode.tscn")
const PATH := "res://temp/replay_test/scene_0101B.replay"
var checks := 0
var failures := 0

func _initialize() -> void: call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)

func settle() -> void:
	for i in 5: await process_frame

func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://temp/replay_test")
	if FileAccess.file_exists(PATH): DirAccess.remove_absolute(PATH)
	var game = Scene.instantiate()
	game.developer_tools_enabled = true
	game.developer_speed_enabled = true
	game.replay_path = PATH
	root.add_child(game)
	game.set_process(false)
	await settle()
	check(game.command("deploy", ["guard", Vector2i(3, 1), 2]).ok, "Record deployment before battle")
	game.start()
	check(game.command("activate_skill", [1]).ok, "Record skill activation")
	game._process(1.0)
	game.toggle_pause()
	check(game.command("retreat", [1]).ok, "Record action while paused")
	game.toggle_pause()
	game._process(0.5)
	check(game.debug_victory(), "Record developer victory")
	var expected: Dictionary = game.battle.snapshot()
	check(game.save_recording() == OK and FileAccess.file_exists(PATH), "Finished battle saves to disk")
	check(game.save_recording() == OK, "Saving again replaces the previous replay")
	var file := FileAccess.open(PATH, FileAccess.READ)
	var data: Dictionary = file.get_var()
	file.close()
	check(data.actions.size() == 5, "Recording contains successful actions and start")
	game.free()
	game = Scene.instantiate()
	game.developer_tools_enabled = true
	game.developer_speed_enabled = true
	game.replay_mode = true
	game.replay_data = data
	root.add_child(game)
	game.set_process(false)
	await settle()
	check(game.battle != null and not game.hud.developer_panel.visible, "Replay loads without developer controls")
	check(game.hud.pause_button.disabled and game.hud.cards.guard.button.disabled, "Gameplay controls are disabled")
	check(not game.command("deploy", ["tank", Vector2i(2, 1), 2]).ok, "Playback rejects player commands")
	game.toggle_pause()
	check(not game.battle.snapshot().paused, "Playback cannot be paused")
	game.set_speed(4.0)
	game._process(0.375)
	check(not game.replay_error and game.battle.snapshot() == expected, "Playback reproduces the recorded result at 4x")
	check(game.hud.result_button.text == "返回关卡", "Playback result returns without starting a new battle")
	game.free()
	game = Scene.instantiate()
	game.replay_mode = true
	game.replay_data = data
	root.add_child(game)
	game.set_process(false)
	game.battle._config.roster.guard.attack += 50.0
	game._process(1.5)
	check(not game.replay_error and game.battle.snapshot().phase == "victory", "Changed combat values do not prevent replay")
	game.free()
	var invalid: Dictionary = data.duplicate(true)
	invalid.actions[0].args[1] = Vector2i(99, 99)
	game = Scene.instantiate()
	game.replay_mode = true
	game.replay_data = invalid
	root.add_child(game)
	game.set_process(false)
	await settle()
	game._process(1.0)
	check(game.replay_error and game.battle.snapshot().time == 0.0 and game.hud.notice.visible, "Invalid recorded command stops replay and reports error")
	check(game.replay_error_message.contains("地形不适合"), "Replay reports the failing command reason")
	game._process(3.0)
	check(game.battle.snapshot().time == 0.0, "Failed replay stays stopped")
	game.free()
	game = Scene.instantiate()
	game.replay_mode = true
	game.replay_data = data
	root.add_child(game)
	game.set_process(false)
	game.battle._config.roster.guard.cost = 999.0
	game._process(1.0)
	check(game.replay_error and game.replay_error_message.contains("费用不足"), "Balance change causing an invalid deployment stops replay")
	game.free()
	var player = Player.instantiate()
	player.developer_mode = true
	player.replay_directory = "res://temp/replay_test"
	player.tutorial_seen = true
	root.add_child(player)
	await settle()
	player.progress.selected = "scene_0101B"
	player.start_battle()
	var dialog: ConfirmationDialog
	for child in player.get_children():
		if child is ConfirmationDialog: dialog = child
	check(dialog != null, "Existing replay offers a playback choice")
	if dialog: dialog.canceled.emit()
	await settle()
	check(player.page == "battle" and not player.battle_scene.replay_mode, "Choice can start a normal battle")
	player.battle_scene.set_process(false)
	player.battle_scene.start()
	player.battle_scene._process(0.2)
	player.battle_scene.debug_victory()
	player.battle_scene.save_replay_button.pressed.emit()
	check(player.battle_scene.save_replay_button.text == "已保存" and FileAccess.file_exists(PATH), "Developer battle saves a level replay from the result")
	var pending: String = player.progress.pending_after
	player.show_levels()
	player.start_battle()
	dialog = null
	for child in player.get_children():
		if child is ConfirmationDialog and not child.is_queued_for_deletion(): dialog = child
	check(dialog != null, "Saved level replay offers playback")
	if dialog: dialog.confirmed.emit()
	await settle()
	check(player.page == "battle" and player.battle_scene.replay_mode, "Choice opens the saved replay")
	player.battle_scene.set_process(false)
	player.battle_scene._process(1.0)
	check(player.battle_scene.last_state.phase == "victory" and player.progress.pending_after == pending, "Replay does not alter campaign progress")
	player._leave_result()
	check(player.page == "levels", "Leaving replay returns to levels")
	player.queue_free()
	await settle()
	if FileAccess.file_exists(PATH): DirAccess.remove_absolute(PATH)
	print("BATTLE REPLAY: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
