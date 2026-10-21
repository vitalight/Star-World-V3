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
func find_button(text: String, prefix_match: bool = false) -> Button:
	for item in buttons(current_scene):
		var matches := item.text.begins_with(text) if prefix_match else item.text == text
		if matches:
			return item
	push_error("Missing button: " + text)
	return null

func paths(node: Node) -> Array[Node]:
	var result: Array[Node] = []
	if node.get_script() == preload("res://devtools/ui/workspace_path.gd"):
		result.append(node)
	for child in node.get_children():
		result.append_array(paths(child))
	return result

func check_path(expected: String) -> void:
	var found := paths(current_scene)
	check(found.size() == 1, "Exactly one shared breadcrumb")
	if found.size() == 1:
		check("/".join(found[0].segments) == expected, "Breadcrumb: " + expected)

func select_tab(index: int) -> void:
	var bar: TabBar = current_scene.tabs.get_tab_bar()
	var point := bar.get_global_rect().position + bar.get_tab_rect(index).get_center()
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		event.position = point
		root.push_input(event, true)
		await process_frame
	await settle()
	check(current_scene.tabs.current_tab == index, "Mouse selects tab %d" % index)
	check_path("Star World/Developer Hub/Art Test")

func check_catalog() -> void:
	var catalog = preload("res://devtools/art_test/asset_catalog.gd")
	var characters = catalog.characters()
	var effects = catalog.effects()
	check(characters.size() == 16, "All 16 characters")
	check(effects.size() == 32, "All 32 effects")
	var regions := {}
	for entry in characters:
		check(entry.poses.size() == 4, "Four poses per character")
		for pose in entry.poses:
			check_slice(pose, regions)
	for entry in effects:
		check_slice(entry.texture, regions)
	check(regions.size() == 96, "96 distinct source slices")

func check_slice(texture: AtlasTexture, regions: Dictionary) -> void:
	var key := texture.atlas.resource_path + str(texture.region)
	check(not regions.has(key), "No duplicated source slice")
	regions[key] = true
	var cell := texture.atlas.get_size() / 4.0
	check(texture.region.size == cell, "Preserve fractional cell dimensions")
	check(Rect2(Vector2.ZERO, texture.atlas.get_size()).encloses(texture.region), "Slice inside atlas")

func check_static() -> void:
	await RenderingServer.frame_post_draw
	var before := root.get_texture().get_image().get_data()
	await create_timer(0.6).timeout
	await RenderingServer.frame_post_draw
	check(before == root.get_texture().get_image().get_data(), "Static tab remains unchanged")

func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://temp/verification"))
	if not FileAccess.file_exists("res://temp/.gdignore"):
		var ignore_file = FileAccess.open("res://temp/.gdignore", FileAccess.WRITE)
		ignore_file.close()
	for repeat in 2:
		change_scene_to_file("res://devtools/hub/developer_hub.tscn")
		await settle()
		check_path("Star World/Developer Hub")
		if repeat == 0: await capture("hub")
		for entry in ["Blueprint", "Art Test", "Logic Test", "Game Test"]:
			var old = weakref(current_scene)
			check(buttons(current_scene).size() == 4, "Hub exposes four workspaces")
			await click_control(find_button(entry, true))
			await settle()
			check(old.get_ref() == null, "Departed hub freed")
			check_path("Star World/Developer Hub/" + entry)
			if repeat == 0: await capture(entry.to_snake_case())
			if entry == "Blueprint":
				await click_control(find_button("B /", true))
				await settle()
				check(current_scene.preview.texture.resource_path.ends_with("concept_b.png"), "Blueprint B selection")
				if repeat == 0: await capture("blueprint_b")
			var workspace = weakref(current_scene)
			await click_control(find_button("Developer Hub"))
			await settle()
			check(workspace.get_ref() == null, "Departed workspace freed")
	check_catalog()
	var scenes := ["character_preview", "effect_preview", "animation_preview", "battle_preview"]
	for index in scenes.size():
		change_scene_to_file("res://devtools/art_test/" + scenes[index] + ".tscn")
		await settle()
		check(current_scene.tabs.current_tab == index, "Independent entry selects tab")
		check_path("Star World/Developer Hub/Art Test")
		await capture(scenes[index])
	change_scene_to_file("res://devtools/art_test/art_workspace.tscn")
	await settle()
	check(current_scene.character_columns.get_child_count() == 16, "16 character columns")
	check(current_scene.tabs.get_tab_count() == 4, "Four persistent tabs")
	for panel in current_scene.character_columns.get_children():
		var images = panel.get_child(0).get_children().filter(func(n): return n is TextureRect)
		check(images.size() == 4, "Four visible static poses in each column")
	await check_static()
	current_scene.character_scroll.scroll_horizontal = 100000
	await settle()
	check(current_scene.character_scroll.scroll_horizontal > 0, "Character horizontal scroll")
	await capture("character_last_columns")
	await select_tab(1)
	check(current_scene.effect_grid.get_child_count() == 32, "32 static effect cards")
	await check_static()
	await select_tab(2)
	check(current_scene.animation_actors.size() == 32, "Both directions of all characters")
	check(current_scene.animation_effects.size() == 32, "All effect pulses")
	await click_control(find_button("重播"))
	await settle()
	var actor = current_scene.animation_actors[0]
	var effect = current_scene.animation_effects[0]
	var initial_frame: int = actor.sprite.frame
	await create_timer(0.55).timeout
	check(actor.sprite.frame != initial_frame, "Pose loop advances")
	await click_control(find_button("暂停"))
	var paused_frame: int = actor.sprite.frame
	var paused_phase: float = effect.phase
	await create_timer(0.6).timeout
	check(actor.sprite.frame == paused_frame and effect.phase == paused_phase, "Pause holds actors and effects")
	for preview in current_scene.animation_actors:
		check(not preview.sprite.is_playing(), "All character previews paused")
	for preview in current_scene.animation_effects:
		check(not preview.is_processing(), "All effect previews paused")
	await select_tab(0)
	await select_tab(2)
	check(not current_scene.animation_playing and not actor.sprite.is_playing(), "Paused preference survives tab switch")
	await click_control(find_button("播放"))
	await create_timer(0.2).timeout
	check(effect.phase != paused_phase, "Play resumes effect")
	await select_tab(1)
	paused_frame = actor.sprite.frame
	paused_phase = effect.phase
	await create_timer(0.6).timeout
	check(actor.sprite.frame == paused_frame and effect.phase == paused_phase, "Hidden Animation stops")
	await select_tab(2)
	check(actor.sprite.is_playing() and effect.is_processing(), "Returning resumes playing preference")
	await click_control(find_button("重播"))
	check(actor.sprite.frame == 0 and effect.phase < 0.2, "Replay resets all previews")
	var animation_scroll: ScrollContainer = current_scene.tabs.get_child(2).get_child(1)
	animation_scroll.scroll_vertical = 100000
	await settle()
	await capture("animation_effects")
	await select_tab(3)
	var battle_stage = current_scene.battle_stage
	await select_tab(0)
	var battle_phase: float = battle_stage.phase
	await create_timer(0.2).timeout
	check(battle_stage.phase == battle_phase, "Hidden Battle stops")
	var original_scale := root.content_scale_size
	var original_size := root.size
	root.content_scale_size = Vector2i(800, 650)
	root.size = Vector2i(800, 650)
	await settle()
	check(current_scene.size.x <= 810, "Narrow logical viewport")
	await capture("character_narrow")
	current_scene.character_scroll.scroll_vertical = 100000
	await settle()
	check(current_scene.character_scroll.scroll_vertical > 0, "Narrow Character supports vertical scrolling")
	await capture("character_narrow_bottom")
	await select_tab(1)
	await capture("effect_narrow")
	check(current_scene.effect_grid.get_child(0).position.y < current_scene.effect_grid.get_child(4).position.y, "Effect grid wraps")
	await select_tab(2)
	await capture("animation_narrow")
	root.content_scale_size = original_scale
	root.size = original_size
	await settle()
	var departed_actor = weakref(actor)
	var departed_effect = weakref(effect)
	await click_control(find_button("Developer Hub"))
	await settle()
	check(departed_actor.get_ref() == null and departed_effect.get_ref() == null, "Leaving frees animation nodes")
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
