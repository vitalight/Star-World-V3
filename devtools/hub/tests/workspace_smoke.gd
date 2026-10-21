## Rendered smoke test. Run without --headless; screenshots stay in temp/verification.
extends SceneTree
var failures := 0
func _initialize() -> void:
	call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
func settle() -> void:
	for i in 8:
		await process_frame
func capture(filename: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://temp/verification/" + filename + ".png")
func buttons(node: Node) -> Array[Button]:
	var result: Array[Button] = []
	for child in node.get_children():
		if child is Button: result.append(child)
		result.append_array(buttons(child))
	return result
func click_control(control: Control) -> void:
	var point = control.get_global_rect().get_center()
	for pressed in [true, false]:
		var event = InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		event.position = point
		root.push_input(event, true)
		await process_frame
func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://temp/verification"))
	if not FileAccess.file_exists("res://temp/.gdignore"):
		var ignore_file = FileAccess.open("res://temp/.gdignore", FileAccess.WRITE)
		ignore_file.close()
	for repeat in 2:
		change_scene_to_file("res://devtools/hub/developer_hub.tscn")
		await settle()
		if repeat == 0: await capture("hub")
		for index in 4:
			var old = weakref(current_scene)
			var menu = buttons(current_scene)
			check(menu.size() == 4, "Hub must expose four workspaces")
			await click_control(menu[index])
			await settle()
			check(old.get_ref() == null, "Departed hub must be freed")
			if repeat == 0: await capture("workspace_%d" % index)
			if index == 0:
				await click_control(buttons(current_scene)[2])
				await settle()
				if repeat == 0: await capture("blueprint_b")
			var workspace = weakref(current_scene)
			var back = buttons(current_scene).filter(func(b): return "Hub" in b.text or "hub" in b.text or "首页" in b.text)
			check(not back.is_empty(), "Workspace needs hub return")
			await click_control(back[0])
			await settle()
			check(workspace.get_ref() == null, "Departed workspace must be freed")
	for page in ["character_preview", "effect_preview", "battle_preview"]:
		change_scene_to_file("res://devtools/art_test/" + page + ".tscn")
		await settle()
		if page == "character_preview":
			var actor = current_scene.actors[0]
			var initial_frame: int = actor.sprite.frame
			await create_timer(0.55).timeout
			check(actor.sprite.frame != initial_frame, "Character pose loop advances")
			actor.set_playing(false)
			var paused_frame: int = actor.sprite.frame
			await create_timer(0.55).timeout
			check(actor.sprite.frame == paused_frame, "Character pause holds frame")
			actor.set_playing(true)
		await capture(page)
		for b in buttons(current_scene):
			if "首页" not in b.text and "目录" not in b.text: b.pressed.emit()
		await settle()
		await capture(page + "_after_controls")
	change_scene_to_file("res://devtools/logic_test/logic_workspace.tscn")
	await settle()
	var canvas = current_scene.canvas
	for slot in canvas.config.slots:
		var point: Vector2 = canvas.global_position + canvas._offset + slot * canvas._scale
		var down = InputEventMouseButton.new()
		down.button_index = MOUSE_BUTTON_LEFT
		down.pressed = true
		down.position = point
		root.push_input(down, true)
		var up = InputEventMouseButton.new()
		up.button_index = MOUSE_BUTTON_LEFT
		up.position = point
		root.push_input(up, true)
		await settle()
	check(current_scene.battle.snapshot().units.size() == 4, "Actual GUI input deploys all four slots")
	await click_control(current_scene.start_button)
	await create_timer(2.5).timeout
	await capture("logic_running")
	current_scene.battle.advance(120.0)
	await settle()
	check(current_scene.battle.snapshot().phase == "victory", "GUI configured battle wins")
	await create_timer(0.3).timeout
	await capture("logic_won")
	current_scene._reset()
	await click_control(current_scene.start_button)
	current_scene.battle.advance(120.0)
	await settle()
	check(current_scene.battle.snapshot().phase == "defeat", "Empty battlefield loses")
	await capture("logic_lost")
	print("Visual/navigation verification: %d failures" % failures)
	quit(failures)



