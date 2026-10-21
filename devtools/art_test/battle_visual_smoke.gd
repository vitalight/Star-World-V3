extends SceneTree
## Run with the real Compatibility renderer; artifacts stay under temp/.
var failures := 0
func _initialize() -> void:
	call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
func settle() -> void:
	for i in 12: await process_frame
func capture(name: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://temp/verification/" + name + ".png")
func find_action(node: Node, text: String) -> Button:
	if node is Button and node.text == text: return node
	for child in node.get_children():
		var found := find_action(child, text)
		if found: return found
	return null
func click(stage: Control, control: Control) -> void:
	var container: Control = stage.viewport.get_parent()
	var point := container.get_global_transform() * control.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new()
	motion.position = point
	root.push_input(motion, true)
	# Keep the input sequence in one frame so native cursor refresh cannot replace the synthetic hover.
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		root.push_input(event, true)
	await process_frame
func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://temp/verification"))
	change_scene_to_file("res://devtools/art_test/battle_preview.tscn")
	await settle()
	var stage = current_scene.battle_stage
	check(stage.actors.size() == 10, "Ten static units")
	check(stage.field.layout.size() == 6, "Six map rows")
	check(stage.hud.portraits.size() == 5, "Five deployment portraits")
	for child in stage.hud.get_children():
		if child is Button and child.get_child_count() > 0:
			check(child.get_child(0).size.x <= 117, "Portrait fits its card")
	await capture("battle_complete")
	await RenderingServer.frame_post_draw
	stage.viewport.get_texture().get_image().save_png("res://temp/verification/battle_canvas.png")
	await click(stage, stage.hud.pause_button)
	var phase: float = stage.phase
	await create_timer(0.25).timeout
	check(stage.paused and stage.phase == phase, "Pause freezes presentation")
	await click(stage, stage.hud.speed_button)
	check(stage.speed == 2.0, "Speed changes to 2x while paused")
	await click(stage, find_action(stage.hud, "☰"))
	check(stage.hud.settings.visible, "Settings menu opens through scaled viewport")
	await capture("battle_settings")
	await click(stage, find_action(stage.hud, "恢复 1×"))
	check(stage.speed == 1, "Settings resets speed through real input")
	await click(stage, find_action(stage.hud, "重播展示"))
	check(not stage.paused, "Settings replay resumes presentation")
	await click(stage, find_action(stage.hud, "☰"))
	check(not stage.hud.settings.visible, "Settings menu closes")
	await click(stage, stage.hud.speed_button)
	await click(stage, stage.hud.pause_button)
	phase = stage.phase
	current_scene.tabs.current_tab = 0
	await settle()
	check(stage.viewport.render_target_update_mode == SubViewport.UPDATE_DISABLED, "Hidden viewport stops rendering")
	current_scene.tabs.current_tab = 3
	await settle()
	check(stage.paused and stage.phase == phase, "Pause preference survives tab switch")
	stage.hud.replay_requested.emit()
	check(not stage.paused and stage.phase == 0, "Replay resets phase and resumes")
	await create_timer(0.2).timeout
	check(stage.phase > 0.3, "2x animation advances")
	stage.hud.reset_speed_requested.emit()
	check(stage.speed == 1, "Default speed restored")
	current_scene.tabs.current_tab = 0
	await settle()
	phase = stage.phase
	await create_timer(0.2).timeout
	check(stage.phase == phase, "Hidden running presentation freezes")
	current_scene.tabs.current_tab = 3
	await settle()
	check(stage.phase > phase, "Returning resumes running presentation")
	for dimensions in [Vector2i(1280, 800), Vector2i(960, 600)]:
		root.content_scale_size = dimensions
		root.size = dimensions
		await settle()
		var body: Control = stage.get_child(0)
		check(absf(body.size.x / body.size.y - 16.0 / 9.0) < 0.01, "16:9 fitted canvas")
		check(root.get_visible_rect().encloses(body.get_global_rect()), "Entire battlefield fits window")
		var previous: bool = stage.paused
		await click(stage, stage.hud.pause_button)
		check(stage.paused != previous, "Scaled pause input at %s" % dimensions)
		await click(stage, stage.hud.pause_button)
		check(stage.paused == previous, "Scaled resume input at %s" % dimensions)
		await capture("battle_%dx%d" % [dimensions.x, dimensions.y])
	var old: WeakRef = weakref(stage)
	change_scene_to_file("res://devtools/hub/developer_hub.tscn")
	await settle()
	check(old.get_ref() == null, "Leaving frees the 3D preview")
	# A separate greybox instance verifies the same camera/layout without textures.
	var gray := AspectRatioContainer.new()
	gray.set_script(preload("res://devtools/art_test/battle_stage.gd"))
	gray.graybox = true
	root.add_child(gray)
	gray.size = Vector2(960, 540)
	gray.set_active(true)
	await settle()
	await RenderingServer.frame_post_draw
	gray.viewport.get_texture().get_image().save_png("res://temp/verification/battle_graybox.png")
	gray.queue_free()
	await settle()
	print("Battle visual verification: %d failures" % failures)
	quit(failures)
