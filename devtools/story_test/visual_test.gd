extends SceneTree
## Actual input and rendered layout regression. Run without --headless.
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func settle() -> void:
	for frame in 8:
		await process_frame

func capture(name: String) -> void:
	await settle()
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://temp/verification/" + name + ".png")

func click(control: Control) -> void:
	var point := control.get_global_rect().get_center()
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		root.push_input(event, true)
		await process_frame
	await settle()

func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://temp/verification"))
	if not FileAccess.file_exists("res://temp/.gdignore"):
		FileAccess.open("res://temp/.gdignore", FileAccess.WRITE).close()
	change_scene_to_file("res://devtools/story_test/story_workspace.tscn")
	await settle()
	await capture("story_single")
	await click(current_scene.continue_button)
	check(current_scene.session.snapshot().id == "contact", "Mouse advances to dual scene")
	await capture("story_dual")
	await click(current_scene.continue_button)
	await capture("story_branch")
	await click(current_scene.choices.get_child(0))
	check(current_scene.session.snapshot().id == "ridge", "Mouse selects route")
	await capture("story_garden")
	await click(current_scene.continue_button)
	check(current_scene.session.snapshot().finished, "Mouse reaches ending")
	await capture("story_end")
	await click(current_scene.toolbar.get_child(3))
	check(current_scene.session.snapshot().id == "arrival", "Toolbar replays story")
	root.content_scale_size = Vector2i(800, 650)
	root.size = Vector2i(800, 650)
	await capture("story_single_narrow")
	await click(current_scene.continue_button)
	await capture("story_dual_narrow")
	await click(current_scene.continue_button)
	await capture("story_branch_narrow")
	for child in current_scene.toolbar.get_children():
		check(Rect2(Vector2.ZERO, Vector2(root.size)).encloses(child.get_global_rect()), "Narrow toolbar remains in viewport")
	for child in current_scene.choices.get_children():
		check(Rect2(Vector2.ZERO, Vector2(root.size)).encloses(child.get_global_rect()), "Narrow branch remains in viewport")
	await click(current_scene.toolbar.get_child(2))
	check(current_scene.modal.visible, "Toolbar opens history")
	check(Rect2(Vector2.ZERO, Vector2(root.size)).encloses(current_scene.modal_panel.get_global_rect()), "History panel fits narrow viewport")
	await capture("story_history_narrow")
	print("Story visual/input: %d failures" % failures)
	quit(1 if failures else 0)
