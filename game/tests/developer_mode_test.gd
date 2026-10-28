extends SceneTree

const Player = preload("res://game/player/player_mode.tscn")
const SAVE := "res://temp/chapter_one/mode_progress.cfg"
var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)

func settle() -> void:
	for i in 6: await process_frame

func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://temp/chapter_one")
	var saved := ConfigFile.new()
	saved.set_value("campaign", "version", 3)
	saved.set_value("campaign", "started", true)
	saved.set_value("campaign", "selected", "scene_0102A")
	saved.set_value("campaign", "completed", ["scene_0101A", "scene_0101B"])
	saved.save(SAVE)
	var player = Player.instantiate()
	player.save_path = SAVE
	root.add_child(player)
	await settle()
	if "--developer-mode" in OS.get_cmdline_user_args():
		check(player.developer_mode and player._level_unlocked("scene_0105A"), "Command-line mode unlocks all stages")
		player.progress.selected = "scene_0101B"
		player.start_battle()
		check(player.battle_scene.hud.developer_panel.visible, "Command-line developer mode displays battle panel")
	else:
		check(not player.developer_mode, "Normal launch is not developer mode")
		player.progress.selected = "scene_0101B"
		player.start_battle()
		check(not player.battle_scene.hud.developer_panel.visible, "Normal player battle hides developer panel")
		await settle()
		saved.save(SAVE)
		player.new_game()
		check(player.progress.selected == "scene_0101A" and player.progress.completed.is_empty(), "New game resets progress")
		check(not player._level_unlocked("scene_0101B"), "New game keeps later stages locked")
		player.resume_game()
		check(player.progress.selected == "scene_0102A" and player.progress.completed.size() == 2, "Load restores original save after starting a new game")
		player.developer_mode = true
		player.new_game()
		check(player._level_unlocked("scene_0105A"), "Developer mode unlocks last stage")
		player._select_level("scene_0104B")
		check(player.progress.selected == "scene_0104B", "Developer can select a later battle")
		player.begin_action()
		check(player.page == "battle" and player.battle_scene.campaign_level == "scene_0104B", "Developer can enter a later battle")
		check(player.battle_scene.hud.developer_panel.visible, "Developer player battle displays panel")
		player.battle_scene.reset()
		check(player.battle_scene.hud.developer_panel.visible, "Restart keeps developer panel expanded")
		var readback := ConfigFile.new()
		readback.load(SAVE)
		check(readback.get_value("campaign", "completed") == ["scene_0101A", "scene_0101B"] and readback.get_value("campaign", "selected") == "scene_0102A", "Developer mode does not alter normal save")
	player.queue_free()
	await settle()
	if not "--developer-mode" in OS.get_cmdline_user_args():
		for button_name in ["Player Mode", "进入 Player Mode →"]:
			change_scene_to_file("res://devtools/hub/developer_hub.tscn")
			await settle()
			var hub := current_scene
			var button: Button = find_button(hub, button_name)
			check(button != null, "Hub entry exists: " + button_name)
			if button: button.pressed.emit()
			await settle()
			check(current_scene != hub and current_scene.developer_mode, "Hub entry opens developer mode: " + button_name)
	print("DEVELOPER MODE: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

func find_button(node: Node, value: String) -> Button:
	for child in node.get_children():
		if child is Button and child.text == value: return child
		var result := find_button(child, value)
		if result: return result
	return null
