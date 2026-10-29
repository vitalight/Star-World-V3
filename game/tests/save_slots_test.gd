extends "res://game/tests/chapter_flow_test.gd"

const SLOT_SAVE := "res://temp/chapter_one/slots_test.cfg"

func slot_button(slot: int, label: String) -> Button:
	var panel := player.find_child("SaveSlot%d" % slot, true, false)
	return button(panel, label) if panel else null

func click_control(target: Control) -> void:
	var point := target.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new(); motion.position = point; motion.global_position = point
	root.push_input(motion, true)
	await process_frame
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = point; event.global_position = point
		event.button_index = MOUSE_BUTTON_LEFT; event.pressed = pressed
		root.push_input(event, true)
	await settle()

func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://temp/chapter_one")
	var paths := [SLOT_SAVE, SLOT_SAVE.get_basename() + "_slot_2.cfg", SLOT_SAVE.get_basename() + "_slot_3.cfg"]
	for path in paths:
		if FileAccess.file_exists(path): DirAccess.remove_absolute(path)
	var legacy := ConfigFile.new()
	legacy.set_value("campaign", "version", 3)
	legacy.set_value("campaign", "started", true)
	legacy.set_value("campaign", "selected", "scene_0102A")
	legacy.set_value("campaign", "completed", ["scene_0101A", "scene_0101B"])
	legacy.save(SLOT_SAVE)
	await spawn(SLOT_SAVE)
	await click("读取存档")
	if "--capture" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://temp/chapter_one/save_slots.png")
	check(player.page == "saves" and slot_button(1, "继续") != null, "Legacy save appears in slot 1")
	check(slot_button(2, "新建") != null and slot_button(3, "新建") != null, "Other slots start empty")
	for dimensions in [Vector2i(960, 600), Vector2i(1280, 800), Vector2i(1600, 900)]:
		root.size = dimensions
		await settle()
		for slot in range(1, 4):
			var card := player.find_child("SaveSlot%d" % slot, true, false) as Control
			check(root.get_visible_rect().encloses(card.get_global_rect()), "Save card fits viewport %s" % str(dimensions))
			var action := slot_button(slot, "继续" if slot == 1 else "新建")
			check(root.get_visible_rect().encloses(action.get_global_rect()), "Save action fits viewport %s" % str(dimensions))
	root.size = Vector2i(1280, 800)
	await click("新建")
	await settle()
	check(player.page == "levels" and FileAccess.file_exists(paths[1]), "New slot is created immediately")
	check(player.progress.completed.is_empty(), "New slot begins with independent progress")
	player.progress.completed.append("scene_0101A")
	player.progress.selected = "scene_0101B"
	player._save_progress()
	player.show_main()
	await click("读取存档")
	slot_button(1, "继续").pressed.emit()
	await settle()
	check(player.progress.selected == "scene_0102A" and player.progress.completed.size() == 2, "Legacy slot remains unchanged")
	player.show_main()
	await click("读取存档")
	slot_button(2, "继续").pressed.emit()
	await settle()
	check(player.progress.selected == "scene_0101B" and player.progress.completed.size() == 1, "Second slot loads its own progress")
	await dispose()
	await spawn(SLOT_SAVE)
	await click("读取存档")
	slot_button(2, "继续").pressed.emit()
	await settle()
	check(player.progress.selected == "scene_0101B", "Second slot survives restart")
	player.show_main()
	await click("读取存档")
	slot_button(2, "删除").pressed.emit()
	await settle()
	var dialog := player.find_child("DeleteSaveConfirmation", true, false) as Control
	check(dialog != null and dialog.visible and FileAccess.file_exists(paths[1]), "Delete opens confirmation without deleting")
	for dimensions in [Vector2i(960, 600), Vector2i(1280, 800), Vector2i(1600, 900)]:
		root.size = dimensions
		await settle()
		for name in ["CancelDelete", "ConfirmDelete"]:
			var control := dialog.find_child(name, true, false) as Control
			check(root.get_visible_rect().encloses(control.get_global_rect()), "Confirmation action fits viewport %s" % str(dimensions))
	root.size = Vector2i(1280, 800)
	await settle()
	await click_control(slot_button(3, "新建"))
	check(player.page == "saves" and not FileAccess.file_exists(paths[2]), "Confirmation blocks underlying save controls")
	if "--capture" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://temp/chapter_one/delete_save.png")
	await click_control(dialog.find_child("CancelDelete", true, false) as Button)
	await settle()
	check(FileAccess.file_exists(paths[1]), "Cancel preserves save")
	slot_button(2, "删除").pressed.emit()
	await settle()
	dialog = player.find_child("DeleteSaveConfirmation", true, false) as Control
	var escape := InputEventKey.new(); escape.keycode = KEY_ESCAPE; escape.pressed = true
	root.push_input(escape, true)
	await settle()
	check(player.find_child("DeleteSaveConfirmation", true, false) == null and FileAccess.file_exists(paths[1]), "Escape cancels without deleting")
	slot_button(2, "删除").pressed.emit()
	await settle()
	dialog = player.find_child("DeleteSaveConfirmation", true, false) as Control
	await click_control(dialog.find_child("ConfirmDelete", true, false) as Button)
	await settle()
	check(not FileAccess.file_exists(paths[1]) and FileAccess.file_exists(paths[0]), "Confirmation deletes only selected save")
	check(slot_button(2, "新建") != null, "Deleted slot becomes available")
	var corrupt := FileAccess.open(paths[2], FileAccess.WRITE)
	corrupt.store_string("invalid progress"); corrupt.close()
	player.show_save_slots()
	check(slot_button(3, "继续") == null and slot_button(3, "删除") != null, "Unreadable save can be deleted but not loaded or overwritten")
	await dispose()
	for path in paths:
		if FileAccess.file_exists(path): DirAccess.remove_absolute(path)
	print("SAVE SLOTS: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
