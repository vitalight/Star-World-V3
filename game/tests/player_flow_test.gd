extends SceneTree
const Player = preload("res://game/player/player_mode.tscn")
const Fixture = preload("res://game/tests/defense_fixture.gd")
const SAVE := "res://temp/player_mode/test_progress.cfg"
var failures := 0
var checks := 0
var player: Control
var capture_enabled := false

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)

func settle() -> void:
	for i in 8: await process_frame

func capture(name: String) -> void:
	if not capture_enabled: return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://temp/player_mode/" + name + ".png")

func find_button(node: Node, text: String) -> Button:
	for child in node.get_children():
		if child is Button and child.text == text: return child
		var found := find_button(child, text)
		if found: return found
	return null

func click(text: String) -> void:
	await settle()
	var button := find_button(player, text)
	check(button != null and not button.disabled, "Action available: " + text)
	if not button or button.disabled: return
	var point := button.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new(); motion.position = point
	root.push_input(motion, true)
	await process_frame
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = point; event.button_index = MOUSE_BUTTON_LEFT; event.pressed = pressed
		root.push_input(event, true)
		await process_frame
	await settle()

func spawn_player() -> void:
	player = Player.instantiate()
	player.save_path = SAVE
	root.add_child(player)
	await settle()

func run() -> void:
	capture_enabled = "--capture" in OS.get_cmdline_user_args()
	DirAccess.make_dir_recursive_absolute("res://temp/player_mode")
	if FileAccess.file_exists(SAVE): DirAccess.remove_absolute(SAVE)
	check(ProjectSettings.get_setting("application/run/main_scene") == "res://game/player/player_mode.tscn", "Default project entry is Player Mode")
	await spawn_player()
	check(player.page == "main" and find_button(player, "读取存档").disabled, "Fresh launch has no continue action")
	await capture("main")
	for dimensions in [Vector2i(1280, 800), Vector2i(960, 600), Vector2i(1600, 900)]:
		root.size = dimensions
		await settle()
		await click("开始游戏")
		check(player.page == "levels", "Start opens level selection")
		for text in ["开始行动   ›", "‹   返回"]:
			check(root.get_visible_rect().encloses(find_button(player, text).get_global_rect()), "Control stays in window: " + str(dimensions) + text)
		await capture("levels_%dx%d" % [dimensions.x, dimensions.y])
		await click("‹   返回")
		check(player.page == "main", "Back returns to main")
	root.size = Vector2i(1280, 800)
	await settle()
	await click("开始游戏")
	await click("开始行动   ›")
	var game = player.battle_scene
	game.set_process(false)
	check(player.page == "battle" and game.validation_errors.is_empty() and game.battle != null, "Player starts the actual authored battle")
	check(find_button(player, "F3") == null, "Product has no developer controls")
	check(FileAccess.file_exists(SAVE), "Starting action writes progress")
	await capture("battle")
	game.start(); game.battle.advance(80); game.refresh()
	check(game.last_state.phase == "defeat" and game.hud.end_panel.visible, "Actual defeat displays result")
	await capture("defeat")
	await click("返回关卡")
	check(player.page == "levels" and not player.completed, "Defeat returns without granting completion")
	await click("开始行动   ›")
	game = player.battle_scene; game.set_process(false)
	for args in Fixture.deployments(): game.command("deploy", args)
	game.start(); game.battle.advance(3); game.refresh(3); game.command("activate_skill", [1])
	await capture("battle_deployed")
	game.battle.advance(60); game.refresh(60)
	check(game.last_state.phase == "victory" and player.completed, "Real victory records completion")
	await capture("victory")
	await click("重新挑战")
	check(game.last_state.phase == "ready", "Replay uses shared battle reset")
	await click("☰")
	await click("退出战斗")
	check(player.page == "levels" and player.battle_scene == null, "Battle menu exits back to level selection")
	await capture("levels_completed")
	await click("‹   返回")
	check(not find_button(player, "读取存档").disabled, "Continue becomes available")
	player.queue_free(); await settle()
	await spawn_player()
	check(player.has_progress and player.completed, "Progress survives a new player session")
	await click("读取存档")
	check(player.page == "levels", "Continue resumes selected level")
	await click("开始行动   ›")
	check(player.battle_scene.last_state.phase == "ready", "Reentering creates a fresh battle")
	player.queue_free(); await settle()
	var corrupt := FileAccess.open(SAVE, FileAccess.WRITE)
	corrupt.store_string("invalid progress"); corrupt.close()
	await spawn_player()
	check(not player.has_progress and not player.completed, "Invalid save safely falls back to a fresh menu")
	player.queue_free(); await settle()
	DirAccess.remove_absolute(SAVE)
	change_scene_to_file("res://devtools/hub/developer_hub.tscn")
	await settle()
	player = current_scene
	await click("Player Mode")
	player = current_scene
	check(player.page == "main", "Developer Hub Player Mode card enters product main menu")
	print("PLAYER FLOW: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
