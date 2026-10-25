extends SceneTree
const Player = preload("res://game/player/player_mode.tscn")
const Fixture = preload("res://game/tests/chapter_fixture.gd")
const SAVE := "res://temp/chapter_one/flow_progress.cfg"
var failures := 0
var checks := 0
var player: Control
var capture_enabled := false

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(message)

func settle() -> void:
	for frame in 5: await process_frame

func capture(name: String) -> void:
	if not capture_enabled: return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://temp/chapter_one/" + name + ".png")

func button(node: Node, text: String) -> Button:
	for child in node.get_children():
		if child is Button and child.text == text: return child
		var found := button(child, text)
		if found: return found
	return null

func click(text: String) -> void:
	await settle()
	var target := button(player, text)
	check(target != null and not target.disabled, "Button available: " + text)
	if not target or target.disabled: return
	var point := target.get_global_rect().get_center()
	check(root.get_visible_rect().encloses(target.get_global_rect()), "Button fits viewport: " + text)
	var motion := InputEventMouseMotion.new(); motion.position = point
	root.push_input(motion, true)
	await process_frame
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = point; event.button_index = MOUSE_BUTTON_LEFT; event.pressed = pressed
		root.push_input(event, true)
		await process_frame
	await settle()

func spawn(path := SAVE) -> void:
	player = Player.instantiate(); player.save_path = path
	root.add_child(player); await settle()

func dispose() -> void:
	player.queue_free(); await settle()

func run() -> void:
	capture_enabled = "--capture" in OS.get_cmdline_user_args()
	DirAccess.make_dir_recursive_absolute("res://temp/chapter_one")
	if FileAccess.file_exists(SAVE): DirAccess.remove_absolute(SAVE)
	await spawn()
	check(player.catalog.errors.is_empty(), "Player loads chapter sources")
	check(button(player, "读取存档").disabled, "Fresh progress disables resume")
	await capture("main")
	await click("开始游戏")
	check(player.page == "levels" and player.progress.selected == "scene_002", "Fresh chapter opens first stage")
	check(not player.progress.unlocked("scene_003", player.catalog.levels.keys()), "Second stage initially locked")
	for dimensions in [Vector2i(1280, 800), Vector2i(960, 600), Vector2i(1600, 900)]:
		root.size = dimensions; await settle()
		await capture("levels_%dx%d" % [dimensions.x, dimensions.y])
		await click("开始行动   ›")
		check(player.page == "story", "Start enters battle introduction")
		await capture("story_%dx%d" % [dimensions.x, dimensions.y])
		await click("返回关卡")
	root.size = Vector2i(1280, 800); await settle()
	await click("开始行动   ›")
	await click("继续 →")
	check(player.session.snapshot().history.size() == 2, "Story continue advances shared session")
	await capture("story_cat")
	await click("跳过剧情")
	check(player.page == "battle" and player.battle_scene.validation_errors.is_empty(), "Skip enters shared chapter battle")
	var game = player.battle_scene; game.set_process(false)
	check(button(player, "F3") == null, "Player battle does not mount the Game Test debug window")
	await click("知道了")
	game.start(); game.battle.advance(300); game.refresh()
	check(game.last_state.phase == "defeat" and player.progress.pending_after.is_empty(), "Defeat does not grant a story or completion")
	await capture("defeat")
	await click("重新挑战")
	check(game.last_state.phase == "ready", "Retry resets the same battle")
	await click("☰"); await click("退出战斗")
	check(player.page == "levels", "Battle menu returns to chapter")
	for id in ["scene_002", "scene_003", "scene_004"]:
		check(player.progress.selected == id, "Selected next stage: " + id)
		await click("开始行动   ›"); await click("跳过剧情")
		game = player.battle_scene; game.set_process(false)
		check(game.campaign_level == id, "Scene receives selected stage")
		for args in Fixture.deployments(id):
			check(game.command("deploy", args).ok, "Chapter deployment: " + str(args))
		game.start(); game.battle.advance(3); game.refresh(3)
		if id == "scene_004":
			check(game.hud.objective_label.visible, "Repair progress is visible")
			await capture("repair")
		else: await capture("battle_" + id)
		game.reset()
		check(Fixture.replay(game.battle, id).is_empty(), "Replay commands accepted")
		game.refresh()
		check(game.last_state.phase == "victory" and player.progress.pending_after == id, "Victory persists pending story: " + id)
		var result_actions: Array = game.hud.end_panel.find_children("*", "Button", true, false).filter(func(action): return action.visible).map(func(action): return action.text)
		check(result_actions == ["继续"], "Victory offers only Continue")
		await capture("victory_" + id)
		if id == "scene_002":
			await dispose(); await spawn()
			check(player.progress.pending_after == id, "Pending story survives restart")
			await click("读取存档")
			check(player.page == "story" and player.story_kind == "after", "Resume continues post-battle story")
		else:
			await click("继续")
		await capture("after_" + id)
		if id == "scene_003":
			for step in 20:
				if player.page != "story": break
				player.advance_story()
			await settle()
		else: await click("跳过剧情")
		check(player.progress.completed.has(id) and player.progress.pending_after.is_empty(), "Reading and skipping both commit progress")
	check(player.completed and player.progress.completed.size() == 3, "Chapter completes after all stories")
	await capture("chapter_complete")
	await dispose(); await spawn()
	check(player.completed, "Completed chapter survives restart")
	player._select_level("scene_002"); player.begin_action()
	check(player.page == "story" and player.story_kind == "before", "Completed stages replay introduction")
	await dispose()
	var legacy := ConfigFile.new()
	legacy.set_value("progress", "selected_level", "scene_001")
	legacy.set_value("progress", "scene_001_completed", true)
	legacy.save(SAVE)
	await spawn()
	check(player.progress.completed.is_empty() and player.progress.selected == "scene_002", "Legacy sample completion does not complete chapter")
	player.progress.started = true; player._save_progress()
	var saved := ConfigFile.new(); saved.load(SAVE)
	check(saved.get_value("progress", "scene_001_completed", false), "Saving retains legacy section")
	await dispose()
	var corrupt := FileAccess.open(SAVE, FileAccess.WRITE)
	corrupt.store_string("invalid progress"); corrupt.close()
	await spawn()
	check(not player.has_progress and player.progress.completed.is_empty(), "Corrupt save falls back to a fresh chapter")
	await dispose()
	await spawn("res://temp/chapter_one/nonexistent/blocked.cfg")
	player.begin_action()
	check(player.save_notice == "进度未能保存" and player.page == "story", "Save failure reported while in-memory play continues")
	await dispose()
	change_scene_to_file("res://devtools/hub/developer_hub.tscn")
	await settle()
	player = current_scene
	await click("Player Mode")
	player = current_scene
	check(player.page == "main", "Developer Hub enters product main menu")
	player.queue_free(); await settle()
	print("CHAPTER FLOW: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
