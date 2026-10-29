extends SceneTree
const Player = preload("res://game/player/player_mode.tscn")
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
	check(target != null and not target.disabled, "Button available: %s (page: %s)" % [text, player.page if "page" in player else str(player.name)])
	if not target or target.disabled: return
	var point := target.get_global_rect().get_center()
	check(root.get_visible_rect().encloses(target.get_global_rect()), "Button fits viewport: " + text)
	# Send GUI input to the viewport without moving the user's native cursor.
	var motion := InputEventMouseMotion.new(); motion.position = point; motion.global_position = point
	root.push_input(motion, true)
	await process_frame
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = point; event.global_position = point
		event.button_index = MOUSE_BUTTON_LEFT; event.pressed = pressed
		root.push_input(event, true)
	await settle()

func click_story_blank() -> void:
	var point: Vector2 = player.story_view.get_global_rect().position + Vector2(40, 200)
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = point; event.global_position = point
		event.button_index = MOUSE_BUTTON_LEFT; event.pressed = pressed
		root.push_input(event, true)
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
	check(player.page == "levels" and player.progress.selected == "scene_0101A", "Fresh chapter opens first stage")
	check(not player.progress.unlocked("scene_0102A", player.catalog.levels.keys()), "Second stage initially locked")
	for dimensions in [Vector2i(1280, 800), Vector2i(960, 600), Vector2i(1600, 900)]:
		root.size = dimensions; await settle()
		await capture("levels_%dx%d" % [dimensions.x, dimensions.y])
		await click("进入故事")
		check(player.page == "story", "Start enters battle introduction")
		await capture("story_%dx%d" % [dimensions.x, dimensions.y])
		await click("返回关卡")
	root.size = Vector2i(1280, 800); await settle()
	await click("进入故事")
	await click_story_blank()
	check(player.session.snapshot().history.size() == 2, "Story continue advances shared session")
	await capture("story_cat")
	await click("跳过剧情")
	check(player.page == "battle" and player.battle_scene.validation_errors.is_empty(), "Skip enters shared chapter battle")
	var game = player.battle_scene; game.set_process(false)
	check(button(player, "F3") == null, "Player battle does not mount the Game Test debug window")
	check(player.tutorial.visible and game.last_state.paused, "Level hint pauses the battle")
	var countdown: float = game.auto_start_left
	game._process(5.0)
	check(game.last_state.time == 0 and game.auto_start_left == countdown, "Level hint freezes battle and automatic start")
	for dimensions in [Vector2i(960, 600), Vector2i(1280, 800), Vector2i(1600, 900)]:
		root.size = dimensions; await settle()
		check(root.get_visible_rect().encloses(player.tutorial.get_global_rect()) and player.tutorial.get_global_rect().get_center().distance_to(root.get_visible_rect().get_center()) < 2.0, "Level hint is centered and fits " + str(dimensions))
	root.size = Vector2i(1280, 800); await settle()
	await capture("battle_level_hint")
	await click("☰")
	check(not game.hud.game_menu.visible and game.last_state.paused, "Level hint blocks underlying battle controls")
	await click("确认")
	check(not game.last_state.paused and player.tutorial == null, "Confirm closes the hint and resumes the battle")
	game.start(); game.battle.advance(300); game.refresh()
	check(game.last_state.phase == "defeat" and player.progress.pending_after.is_empty(), "Defeat does not grant a story or completion")
	await capture("defeat")
	await click("重新挑战")
	check(game.last_state.phase == "ready", "Retry resets the same battle")
	await click("☰"); await click("退出战斗")
	check(player.page == "levels", "Battle menu returns to chapter")
	for index in range(1, 5):
		var story_id := "scene_01%02dA" % index
		var id := "scene_01%02dB" % index
		if index == 1:
			check(player.progress.selected == id, "Completed opening resumes at battle")
			await click("开始战斗")
		else:
			check(player.page == "story" and player.story_level == story_id, "Victory opens next story")
			await click("跳过剧情")
		game = player.battle_scene; game.set_process(false)
		check(game.campaign_level == id, "Story enters corresponding battle")
		check(game.debug_victory(), "Battle victory advances the player flow")
		check(game.last_state.phase == "victory" and player.progress.pending_after == id, "Victory persists pending continuation")
		if index == 1:
			await dispose(); await spawn()
			check(player.progress.pending_after == id, "Pending victory survives restart")
			await click("读取存档")
		else: await click("继续")
		check(player.progress.completed.has(id) and player.progress.pending_after.is_empty(), "Victory transition commits progress")
	check(player.page == "levels" and player.progress.selected == "scene_0104C", "Root node victory unlocks final boss")
	await click("开始战斗")
	game = player.battle_scene; game.set_process(false)
	check(game.campaign_level == "scene_0104C", "Final boss starts directly from selection")
	check(game.debug_victory(), "Final boss victory advances the player flow")
	check(game.last_state.phase == "victory" and player.progress.pending_after == "scene_0104C", "Final boss persists pending continuation")
	await click("继续")
	check(player.progress.completed.has("scene_0104C") and player.progress.pending_after.is_empty(), "Final boss transition commits progress")
	check(player.page == "story" and player.story_level == "scene_0105A", "Final victory opens epilogue")
	await click("跳过剧情")
	check(player.completed and player.progress.completed.size() == 10, "Chapter completes after independent epilogue")
	await capture("chapter_complete")
	await dispose(); await spawn()
	check(player.completed, "Completed chapter survives restart")
	player._select_level("scene_0101A"); player.begin_action()
	check(player.page == "story", "Completed story can be replayed")
	await click("跳过剧情")
	check(player.page == "levels", "Replayed story returns to selection")
	player._select_level("scene_0101B"); player.begin_action()
	check(player.page == "battle", "Selecting battle directly starts battle")
	await dispose()
	var legacy := ConfigFile.new()
	legacy.set_value("progress", "selected_level", "scene_001")
	legacy.set_value("progress", "scene_001_completed", true)
	legacy.save(SAVE)
	await spawn()
	check(player.progress.completed.is_empty() and player.progress.selected == "scene_0101A", "Legacy sample completion does not complete chapter")
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
