extends "res://game/tests/chapter_flow_test.gd"
## Native UI coverage: debug command must use normal result, story and save flow.
const DEBUG_SAVE := "res://temp/chapter_one/developer_progress.cfg"

func run() -> void:
	capture_enabled = "--capture" in OS.get_cmdline_user_args()
	DirAccess.make_dir_recursive_absolute("res://temp/chapter_one")
	if FileAccess.file_exists(DEBUG_SAVE): DirAccess.remove_absolute(DEBUG_SAVE)
	await spawn(DEBUG_SAVE)
	await click("开始游戏")
	for id in ["scene_0101B", "scene_0102B", "scene_0103B", "scene_0104B"]:
		if player.page == "levels": await click("开始行动   ›")
		player.developer_mode = true
		await click("跳过剧情")
		player.developer_mode = false
		var game = player.battle_scene
		game.set_process(false)
		if id == "scene_0101B": await click("知道了")
		if id == "scene_0104B":
			game.start()
			await settle()
			var point: Vector2 = game.hud.pause_button.get_global_rect().get_center()
			for pressed in [true, false]:
				var event := InputEventMouseButton.new()
				event.position = point; event.button_index = MOUSE_BUTTON_LEFT; event.pressed = pressed
				root.push_input(event, true)
				await process_frame
			check(game.last_state.paused, "Final stage skip starts from a paused running battle")
		var before: Dictionary = game.battle.snapshot()
		check(game.hud.developer_panel.visible and not game.hud.game_menu.visible, "Developer panel is expanded without opening menu")
		var panel_rect: Rect2 = game.hud.developer_panel.get_rect()
		check(is_equal_approx(panel_rect.position.x, 18) and abs(panel_rect.end.y - (game.hud.size.y - 18)) < 1, "Developer panel is anchored at bottom left")
		check(game.battle.snapshot() == before, "Developer panel does not pause or mutate simulation")
		await capture("developer_panel_" + id)
		await click("跳过战斗并胜利")
		check(game.last_state.phase == "victory" and game.hud.end_panel.visible, "Skip uses actual victory result")
		check(not game.hud.developer_panel.visible and game.hud.debug_victory_button.disabled, "Terminal result closes panel and disables repeated skip")
		check(player.progress.pending_after == id and not player.progress.completed.has(id), "Win persists pending story before unlock")
		check(not game.debug_victory(), "Repeated terminal skip is ignored")
		await capture("developer_victory_" + id)
		if id == "scene_0101B":
			await dispose()
			await spawn(DEBUG_SAVE)
			await click("读取存档")
			check(player.page == "story" and player.story_kind == "story" and player.story_level == "scene_0102A", "Developer victory resumes next merged story across restart")
		else: await click("继续")
		if id == "scene_0104B": await click("跳过剧情")
		check(player.progress.completed.has(id), "Developer win commits progress through normal continuation")
	check(player.completed, "Developer skips can complete the chapter")
	await dispose()
	print("DEVELOPER VICTORY: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
