extends SceneTree
const Fixture = preload("res://game/tests/defense_fixture.gd")
var failures := 0
var checks := 0
var game: Node3D
var workspace: Control

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)

func settle() -> void:
	for i in 6: await process_frame

func capture(name: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://temp/verification/" + name + ".png")

func click(point: Vector2, button := MOUSE_BUTTON_LEFT) -> void:
	var motion := InputEventMouseMotion.new(); motion.position = point
	root.push_input(motion, true)
	await process_frame
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = point; event.button_index = button; event.pressed = pressed
		root.push_input(event, true)
		await process_frame

func key(code: Key) -> void:
	var event := InputEventKey.new(); event.keycode = code; event.pressed = true
	root.push_input(event, true)
	await process_frame
	event = InputEventKey.new(); event.keycode = code; event.pressed = false
	root.push_input(event, true)
	await process_frame

func find_button(node: Node, text: String) -> Button:
	for child in node.get_children():
		if child is Button and child.text == text: return child
		var found := find_button(child, text)
		if found: return found
	return null

func click_button(node: Node, text: String) -> void:
	await settle()
	var button := find_button(node, text)
	check(button != null, "Button exists: " + text)
	if button: await click(button.get_global_rect().get_center())

func drag(from: Vector2, to: Vector2) -> void:
	var down := InputEventMouseButton.new(); down.position = from; down.button_index = MOUSE_BUTTON_LEFT; down.pressed = true
	root.push_input(down, true); await process_frame
	var motion := InputEventMouseMotion.new(); motion.position = to; motion.relative = to - from; motion.button_mask = MOUSE_BUTTON_MASK_LEFT
	root.push_input(motion, true); await process_frame
	var up := InputEventMouseButton.new(); up.position = to; up.button_index = MOUSE_BUTTON_LEFT
	root.push_input(up, true); await process_frame

func deploy(args: Array) -> void:
	await click(game.hud.cards[args[0]].button.get_global_rect().get_center())
	check(game.selected_roster == args[0], "Card selects " + args[0])
	var cell: Vector2i = args[1]
	var point: Vector2 = game.camera.unproject_position(Vector3(cell.x, game.field.surface_height(cell), cell.y))
	check(game.pick_cell(point) == cell, "Ray picks authored surface " + str(cell))
	await drag(game.hud.cards[args[0]].button.get_global_rect().get_center(), point)
	check(game.candidate == cell and game.deployment_pending, "Cell opens direction confirmation")
	await settle()
	var directions := [Vector3.RIGHT,Vector3.BACK,Vector3.LEFT,Vector3.FORWARD]
	var origin := Vector3(cell.x,game.field.surface_height(cell),cell.y)
	var aim: Vector2 = (game.camera.unproject_position(origin + directions[args[2]]) - point).normalized()
	await click(point + aim * 85)
	check(game.selected_roster.is_empty() and game.last_state.units.any(func(unit): return unit.roster_id == args[0]), "Confirm deploys through normal input")
	check(not game.hud.cards[args[0]].button.visible, "Deployed card leaves the roster")
	await settle()
	var visible_cards: Array = game.hud.bottom.get_children().filter(func(card): return card.visible)
	for i in range(1, visible_cards.size()):
		check(is_equal_approx(visible_cards[i].position.x - visible_cards[i-1].get_rect().end.x, 5.0), "Roster compacts without gaps")
	await key(KEY_ESCAPE)

func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://temp/verification")
	change_scene_to_file("res://game/tests/game_workspace_fixture.tscn")
	await settle()
	workspace = current_scene; game = workspace.game
	game.set_process(false)
	check(root.get_child_count() > 0 and game.battle != null, "Full game loaded")
	check(not workspace.debug_window.visible, "Debug hidden by default")
	for dimensions in [Vector2i(1280, 800), Vector2i(960, 600), Vector2i(1600, 900)]:
		root.size = dimensions
		await settle()
		game.fit_camera()
		check(game.hud.size.is_equal_approx(root.get_visible_rect().size), "HUD fills viewport " + str(dimensions))
		for card in game.hud.cards.values():
			check(root.get_visible_rect().encloses(card.button.get_global_rect()), "Card stays inside viewport")
			check(card.portrait.texture == game.hud.catalog[game.hud.cards.find_key(card)].portrait and card.portrait.stretch_mode == TextureRect.STRETCH_KEEP_ASPECT_CENTERED, "Roster displays the complete portrait")
		for cell in game.map_data.cells():
			var at := Vector3(cell.x, game.field.surface_height(cell) + 0.015, cell.y)
			var point: Vector2 = game.camera.unproject_position(at)
			check(game.pick_cell(point) == cell, "Picking stays aligned after resize")
			check(root.get_visible_rect().has_point(point), "Every playable cell remains visible")
		await capture("game_%dx%d" % [dimensions.x, dimensions.y])
	root.size = Vector2i(1280, 800)
	await settle()
	game.fit_camera()
	await click_button(game.hud, "☰")
	check(game.hud.game_menu.visible, "Game menu opens above the battlefield")
	await capture("game_two_action_menu")
	await click_button(game.hud.game_menu, "重新开始")
	check(game.last_state.phase == "ready" and not game.hud.game_menu.visible, "Game menu restarts and closes")
	var deployment_index := 0
	for args in Fixture.deployments():
		await deploy(args)
		deployment_index += 1
		if deployment_index == 2: await capture("game_partial_roster")
	for actor in game.presentation.actors.values():
		check(not actor.health.visible and actor.health_bar.visible, "Actors use compact health bars without permanent numbers")
	check(game.last_state.units.size() == 5, "All five roles deployed by native mouse events")
	await capture("game_deployed")
	game._process(1.0)
	check(game.last_state.phase == "running", "Preparation automatically advances to running")
	game.battle.advance(3); game.refresh(3)
	await capture("game_fighting")
	await click(game.camera.unproject_position(Vector3(3, 0.015, 1)))
	check(game.selected_unit == 1, "Click friendly selects unit")
	await key(KEY_ESCAPE)
	await click(game.camera.unproject_position(game.presentation.actors[1].visual_position() + game.camera.global_basis.y * 0.65))
	check(game.selected_unit == 1, "Clicking actor body also selects its instance")
	await click(game.hud.skill_button.get_global_rect().get_center())
	check(game.battle.find_unit(1).skill_left > 0, "Skill button submits command")
	await click(game.hud.pause_button.get_global_rect().get_center())
	check(game.last_state.paused, "Pause button pauses simulation")
	check(game.hud.pause_button.text.is_empty() and game.hud.pause_button.accessibility_name == "继续", "Pause control shows a play icon when paused")
	var state: Dictionary = game.last_state.duplicate(true)
	var actor = game.presentation.actors[1]
	var alpha: Color = actor.sprite.modulate
	game._process(0.5)
	check(game.last_state == state and actor.sprite.modulate == alpha, "Paused simulation and presentation remain frozen")
	await key(KEY_F3)
	var debug = workspace.debug_window
	check(debug.visible, "F3 opens embedded debug")
	var before: int = game.selected_unit
	await click(debug.get_global_rect().position + Vector2(180, 220))
	check(game.selected_unit == before, "Debug panel mouse does not select terrain behind it")
	await key(KEY_ESCAPE)
	check(game.selected_unit == before, "Debug panel keyboard does not cancel gameplay selection")
	var old_position: Vector2 = debug.position
	await drag(debug.title_bar.get_global_rect().position + Vector2(100, 12), debug.title_bar.get_global_rect().position + Vector2(260, 65))
	check(debug.position != old_position, "Embedded debug title drags")
	var old_size: Vector2 = debug.size
	var handle: Button = find_button(debug, "◢")
	await drag(handle.get_global_rect().get_center(), handle.get_global_rect().get_center() + Vector2(100, 70))
	check(debug.size != old_size, "Embedded debug resizes")
	await click_button(debug, "单步")
	check(game.last_state.time > state.time, "Debug single step advances paused battle")
	await capture("game_debug")
	await key(KEY_F3)
	check(not debug.visible, "F3 closes focused debug")
	await click(game.hud.retreat_button.get_global_rect().get_center())
	await settle()
	check(game.hud.cards.guard.button.visible and game.hud.cards.guard.cooldown.visible, "Retreat via GUI restores the cooling card")
	check(game.hud.cards.guard.button.get_global_rect().end.x == game.hud.bottom.get_global_rect().end.x, "Single restored card aligns to the right edge")
	await capture("game_redeploy")
	game.reset(); game.start(); game.battle.advance(180); game.refresh()
	check(game.last_state.phase == "defeat" and game.hud.end_panel.visible, "Defeat screen shown")
	await settle(); await capture("game_defeat")
	await click_button(game.hud.end_panel, "重新挑战")
	check(game.last_state.phase == "ready" and game.presentation.actors.is_empty(), "Retry clears all views")
	for args in Fixture.deployments(): game.command("deploy", args)
	game.start()
	game.battle.advance(3); game.refresh(3); game.command("activate_skill", [1])
	game.battle.advance(180); game.refresh(180)
	check(game.last_state.phase == "victory" and game.hud.end_panel.visible, "Victory screen shown")
	await settle(); await capture("game_victory")
	var old = weakref(workspace)
	await click_button(game.hud, "☰")
	await settle()
	await click_button(game.hud.game_menu, "退出战斗")
	await settle()
	check(old.get_ref() == null, "Leaving Game Test releases workspace and world")
	for repeat in 2:
		change_scene_to_file("res://game/tests/game_workspace_fixture.tscn")
		await settle()
		check(current_scene.game.last_state.phase == "ready", "Reenter starts fresh")
		change_scene_to_file("res://devtools/hub/developer_hub.tscn")
		await settle()
	change_scene_to_file("res://content/scenes/scene_001/map.tscn")
	await settle()
	var tiles: TileMapLayer = current_scene.get_node("Terrain")
	check(tiles.tile_set.get_source(0).texture_region_size == tiles.tile_set.tile_size, "Editor tiles fit the paint grid without overlap")
	await capture("game_editable_map")
	change_scene_to_file("res://content/scenes/scene_001/preview.tscn")
	await settle()
	check(current_scene.get_node("Field").cells.size() == 60, "Standalone 3D preview reads the authored TileMap")
	await capture("game_map_preview")
	print("GAME VISUAL: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
