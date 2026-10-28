extends SceneTree
const Battle = preload("res://features/battle/battle.gd")
const Navigation = preload("res://features/battle/navigation.gd")
var checks := 0
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(message)
func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://temp/verification")
	root.size = Vector2i(1280, 800)
	var game = load("res://game/tests/sample_battle_fixture.tscn").instantiate()
	root.add_child(game); game.set_process(false)
	for frame in 6: await process_frame
	var config: Dictionary = game.configuration.duplicate(true)
	config.life = 10
	config.route_warning_duration = 0.0
	config.waves = [{"time":0.0,"count":1,"interval":1.0,"enemy":"soldier","route":"upper"}, {"time":0.0,"count":1,"interval":1.0,"enemy":"soldier","route":"lower"}]
	game.battle = Battle.new(config); game.refresh(); game.start()
	var bases: Array = game.markers.get_children().filter(func(marker): return marker.get_meta("is_base", false))
	check(bases.size() == 2 and not game.hud.leak_warning.visible, "Distant enemies do not warn")
	game.battle.advance(0.05); game.refresh(0.05)
	var boundary: Dictionary = game.last_state.duplicate(true)
	boundary.enemies = [boundary.enemies[0]]
	var route: Array = config.routes[boundary.enemies[0].route]
	boundary.enemies[0].distance = Navigation.length_of(route) - 1.01
	game.leak_warning.sync(boundary, [])
	check(not game.hud.leak_warning.visible, "More than one tile from the end does not warn")
	boundary.enemies[0].distance = Navigation.length_of(route) - 1.0
	game.leak_warning.sync(boundary, [])
	check(game.hud.leak_warning.visible, "Exactly one tile from the end warns")
	game.refresh()
	var simultaneous := false
	for step in 1000:
		game.battle.advance(0.05); game.refresh(0.05)
		if game.hud.leak_warning.visible:
			simultaneous = bases.all(func(marker): return marker.get_meta("threatened", false))
			break
	check(simultaneous, "Each threatened endpoint warns for simultaneous routes")
	check(game.hud.leak_warning.text == "敌人接近！", "Warning text is visible")
	var one_route: Dictionary = game.last_state.duplicate(true)
	one_route.enemies = [one_route.enemies[0]]
	game.leak_warning.sync(one_route, [])
	check(bases.filter(func(marker): return marker.get_meta("threatened", false)).size() == 1, "Only the threatened endpoint flashes")
	game.refresh()
	for frame in 4: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://temp/verification/leak_warning.png")
	var colors: Array = bases.map(func(marker): return marker.get_child(0).material_override.albedo_color)
	game.toggle_pause(); game._process(0.5)
	check(colors == bases.map(func(marker): return marker.get_child(0).material_override.albedo_color), "Paused warning freezes")
	game.toggle_pause()
	var blocked: Dictionary = game.last_state.duplicate(true)
	for enemy in blocked.enemies: enemy.blocked_by = 999
	game.leak_warning.sync(blocked, [])
	check(not game.hud.leak_warning.visible and bases.all(func(marker): return not marker.get_meta("threatened", false)), "Blocked enemies do not warn")
	game.refresh()
	for step in 1000:
		game.battle.advance(0.05); game.refresh(0.05)
		if game.last_state.escaped > 0: break
	check(game.last_state.escaped > 0 and game.hud.life_status.get_theme_color("font_color").r > 0.99 and game.hud.life_status.get_theme_color("font_color").g < 0.3, "Real leak flashes the life indicator red")
	game.leak_warning.sync(game.last_state, [], 0.0)
	check(game.hud.life_status.get_theme_color("font_color").g < 0.3, "No elapsed time keeps the life flash frozen")
	game._process(1.0)
	check(game.hud.life_status.get_theme_color("font_color").g > 0.8, "Life indicator returns to normal")
	game.reset()
	check(not game.hud.leak_warning.visible and bases.all(func(marker): return not marker.get_meta("threatened", false)), "Reset clears warning and marker state")
	game.free(); await process_frame
	print("LEAK WARNING: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
