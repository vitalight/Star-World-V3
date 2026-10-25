extends "res://game/tests/chapter_flow_test.gd"
## Native UI coverage: debug command must use normal result, story and save flow.
const DEBUG_SAVE := "res://temp/chapter_one/developer_progress.cfg"

func run() -> void:
	capture_enabled = "--capture" in OS.get_cmdline_user_args()
	DirAccess.make_dir_recursive_absolute("res://temp/chapter_one")
	if FileAccess.file_exists(DEBUG_SAVE): DirAccess.remove_absolute(DEBUG_SAVE)
	await spawn(DEBUG_SAVE)
	await click("开始游戏")
	for id in ["scene_002", "scene_003", "scene_004"]:
		await click("开始行动   ›")
		await click("跳过剧情")
		var game = player.battle_scene
		game.set_process(false)
		if id == "scene_002": await click("知道了")
		if id == "scene_004":
			game.start()
			await click("Ⅱ")
			check(game.last_state.paused, "Final stage skip starts from a paused running battle")
		var before: Dictionary = game.battle.snapshot()
		await click("☰")
		await click("开发者面板")
		check(game.hud.developer_panel.visible and not game.hud.game_menu.visible, "Menu opens developer panel")
		check(game.battle.snapshot() == before, "Opening panel does not pause or mutate simulation")
		await capture("developer_panel_" + id)
		await click("跳过战斗并胜利")
		check(game.last_state.phase == "victory" and game.hud.end_panel.visible, "Skip uses actual victory result")
		check(not game.hud.developer_panel.visible and game.hud.debug_victory_button.disabled, "Terminal result closes panel and disables repeated skip")
		check(player.progress.pending_after == id and not player.progress.completed.has(id), "Win persists pending story before unlock")
		check(not game.debug_victory(), "Repeated terminal skip is ignored")
		await capture("developer_victory_" + id)
		if id == "scene_002":
			await dispose()
			await spawn(DEBUG_SAVE)
			await click("读取存档")
			check(player.page == "story" and player.story_kind == "after", "Developer victory resumes post-battle story across restart")
		else: await click("继续")
		await click("跳过剧情")
		check(player.progress.completed.has(id), "Developer win unlocks progress through normal story completion")
	check(player.completed, "Developer skips can complete the chapter")
	await dispose()
	print("DEVELOPER VICTORY: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
