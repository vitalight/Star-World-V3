extends "res://game/tests/chapter_flow_test.gd"
## Native UI coverage: debug command must use normal result, story and save flow.
const DEBUG_SAVE := "res://temp/chapter_one/developer_progress.cfg"

func run() -> void:
	capture_enabled = "--capture" in OS.get_cmdline_user_args()
	DirAccess.make_dir_recursive_absolute("res://temp/chapter_one")
	if FileAccess.file_exists(DEBUG_SAVE): DirAccess.remove_absolute(DEBUG_SAVE)
	await spawn(DEBUG_SAVE)
	await click("开始游戏")
	for id in ["scene_0101B", "scene_0102B", "scene_0103B", "scene_0104B", "scene_0104C"]:
		player.developer_mode = true
		if player.page == "levels": await click("进入故事" if player.catalog.levels[player.progress.selected].type == "story" else "开始战斗")
		if player.page == "story": await click("跳过剧情")
		player.developer_mode = false
		var game = player.battle_scene
		game.set_process(false)
		if id == "scene_0101B": await click("确认")
		if id == "scene_0104C":
			game.start()
			await settle()
			var point: Vector2 = game.hud.pause_button.get_global_rect().get_center()
			for pressed in [true, false]:
				var event := InputEventMouseButton.new()
				event.position = point; event.button_index = MOUSE_BUTTON_LEFT; event.pressed = pressed
				root.push_input(event, true)
				await process_frame
			check(game.last_state.paused, "Final stage skip starts from a paused running battle")
		var air_markers: Array = game.markers.get_children().filter(func(marker): return marker.get_meta("is_air", false))
		check(air_markers.size() == (1 if id in ["scene_0102B", "scene_0103B", "scene_0104C"] else 0), "Flying routes use a distinct aerial entry marker")
		if not air_markers.is_empty():
			var air = air_markers[0]
			var expected_entry := Vector2i(0, 2) if id == "scene_0104C" else Vector2i(0, 0)
			check(air.get_children().any(func(child): return child is Sprite3D) and air.get_meta("endpoint_cell") == expected_entry, "Aerial marker uses its texture at the flying route start")
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
		check(player.progress.completed.has(id), "Developer win commits progress through normal continuation")
	check(player.page == "story" and player.story_level == "scene_0105A", "Final victory opens epilogue")
	await click("跳过剧情")
	check(player.completed, "Developer skips can complete the chapter")
	await dispose()
	print("DEVELOPER VICTORY: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
