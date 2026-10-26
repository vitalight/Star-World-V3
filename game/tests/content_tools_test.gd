extends SceneTree
var failures := 0
var checks := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(message)

func settle() -> void:
	for frame in 5: await process_frame

func capture(name: String) -> void:
	if not "--capture" in OS.get_cmdline_user_args(): return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://temp/chapter_one/" + name + ".png")

func run() -> void:
	var workspace = load("res://devtools/game_test/game_workspace.tscn").instantiate()
	root.add_child(workspace); await settle()
	workspace.game.set_process(false)
	var picker: OptionButton = workspace.debug_window.level_picker
	check(picker.item_count == 4, "Game Test offers sample plus chapter")
	for index in [1, 2, 3, 0]:
		picker.select(index); picker.item_selected.emit(index)
		check(workspace.game.battle != null and workspace.game.validation_errors.is_empty(), "Game Test selection loads valid battle " + str(index))
		workspace.game.reload_level()
		check(workspace.game.battle.snapshot().phase == "ready", "Saved content reload resets battle")
		if index == 3:
			workspace.debug_window.show()
			await settle(); await capture("game_test_chapter")
			workspace.debug_window.hide()
	workspace.game.campaign_level = "scene_999"
	workspace.game.reload_level()
	await settle()
	check(workspace.game.battle == null and not workspace.game.validation_errors.is_empty(), "Invalid content prevents battle creation")
	check(root.get_visible_rect().encloses(workspace.game.hud.get_child(0).get_global_rect()), "Configuration diagnostics fit the viewport")
	workspace.game.campaign_level = "scene_002"
	workspace.game.reload_level()
	check(workspace.game.battle != null, "Fixing content can reload after a configuration failure")
	workspace.queue_free(); await settle()
	workspace = load("res://devtools/story_test/story_workspace.tscn").instantiate()
	root.add_child(workspace); await settle()
	check(workspace.source_picker.item_count == 4, "Story Test offers only three stage stories and chapter epilogue")
	for index in range(4):
		workspace.source_picker.select(index)
		workspace._load_source(index)
		check(not workspace.modal.visible and workspace.session.snapshot().type == "line", "Story Test loads chapter scene " + str(index))
		if index == 2:
			await settle(); await capture("story_test_chapter")
	workspace._load_source(0)
	check(workspace.source_picker.get_item_metadata(0) == ["scene_002", "before"] and workspace.session.snapshot().text.contains("突然停电"), "Story Test defaults to formal 1-1 opening")
	workspace.queue_free(); await settle()
	print("CONTENT TOOLS: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
