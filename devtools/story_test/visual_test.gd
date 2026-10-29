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
	if control == current_scene.stage and current_scene.stage.is_typing():
		current_scene.stage.reveal_dialogue()
	var point := control.get_global_rect().get_center()
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		root.push_input(event, true)
		await process_frame
	await settle()

func toolbar_button(text: String) -> Button:
	for child in current_scene.toolbar.get_children():
		if child is Button and child.text == text: return child
	return null

func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://temp/verification"))
	if not FileAccess.file_exists("res://temp/.gdignore"):
		FileAccess.open("res://temp/.gdignore", FileAccess.WRITE).close()
	change_scene_to_file("res://devtools/story_test/story_workspace.tscn")
	await settle()
	await capture("story_opening")
	await click(current_scene.stage)
	check(current_scene.session.snapshot().id == "line_1", "Mouse advances to protagonist scene")
	await click(toolbar_button("回退"))
	check(current_scene.session.snapshot().id == "line_0", "Mouse returns to previous dialogue")
	await click(current_scene.stage)
	await capture("story_single")
	await click(current_scene.stage)
	await capture("story_portal")
	await click(current_scene.stage)
	for index in 20:
		if current_scene.session.snapshot().actors == ["character_012"]: break
		await click(current_scene.stage)
	check(current_scene.session.snapshot().actors == ["character_012"], "Mouse reaches cat scene")
	await capture("story_cat")
	await click(toolbar_button("跳过 ▸"))
	check(current_scene.session.snapshot().finished, "Mouse reaches ending")
	await capture("story_end")
	await click(toolbar_button("重播剧情"))
	check(current_scene.session.snapshot().id == "line_0", "Toolbar replays formal story")
	root.content_scale_size = Vector2i(800, 650)
	root.size = Vector2i(800, 650)
	await capture("story_opening_narrow")
	await click(current_scene.stage)
	await capture("story_single_narrow")
	await click(current_scene.stage)
	await capture("story_portal_narrow")
	for child in current_scene.toolbar.get_children():
		check(Rect2(Vector2.ZERO, Vector2(root.size)).encloses(child.get_global_rect()), "Narrow toolbar remains in viewport")
	await click(toolbar_button("记录"))
	check(current_scene.modal.visible, "Toolbar opens history")
	check(Rect2(Vector2.ZERO, Vector2(root.size)).encloses(current_scene.modal_panel.get_global_rect()), "History panel fits narrow viewport")
	await capture("story_history_narrow")
	current_scene.modal.hide()
	for dimensions in [Vector2i(800, 650), Vector2i(1600, 900)]:
		root.content_scale_size = dimensions
		root.size = dimensions
		await settle()
		current_scene.stage.show_snapshot({"type": "line", "speaker": "阿五", "text": "定位到了。\n但是……"})
		await settle()
		var scroll: ScrollContainer = current_scene.stage.dialogue.get_parent()
		var bar := scroll.get_v_scroll_bar()
		check(bar.max_value <= bar.page, "Two-line dialogue fits without clipping at " + str(dimensions))
		await capture("story_multiline_%dx%d" % [dimensions.x, dimensions.y])
	print("Story visual/input: %d failures" % failures)
	quit(1 if failures else 0)
