extends SceneTree
## Same snapshot must produce the same view in the Art and Game workspaces.
var checks := 0
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)
func run() -> void:
	root.content_scale_size = Vector2i(1280,720)
	root.size = Vector2i(1280,720)
	var game = load("res://game/battle/battle_scene.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	var art = load("res://devtools/art_test/battle_stage.gd").new()
	root.add_child(art)
	art.size = Vector2(1280,720)
	art.set_active(true)
	art.paused = true; art.sync_playback()
	for frame in 12: await process_frame
	game.fit_camera()
	check(art.hud.get_script() == game.hud.get_script(), "One HUD implementation")
	check(art.presentation.get_script() == game.presentation.get_script(), "One snapshot presentation adapter")
	check(art.camera.transform.is_equal_approx(game.camera.transform) and is_equal_approx(art.camera.v_offset, game.camera.v_offset), "Same framing for same canvas")
	check(art.markers.get_child_count() == game.markers.get_child_count(), "Route markers come from same map")
	for index in art.markers.get_child_count():
		var a = art.markers.get_child(index)
		var b = game.markers.get_child(index)
		check(a.position.is_equal_approx(b.position) and a.get_meta("portal_color") == b.get_meta("portal_color"), "Matching route endpoint style and position")
		check(a.get_child_count() == 12 and b.get_child_count() == 12, "Art-style twelve-edge portal")
		for edge in 12:
			check(a.get_child(edge).position.is_equal_approx(b.get_child(edge).position) and a.get_child(edge).mesh.size == b.get_child(edge).mesh.size, "Matching portal geometry")
	game.presentation.sync(art.mock_state, [], 0.0)
	game.hud.update_state(art.mock_state, "", -1, art.speed, game.configuration.deploy_limit)
	check(art.presentation.route_guides.size() == game.presentation.route_guides.size(), "Same route-warning view count")
	for id in art.presentation.route_guides:
		var a = art.presentation.route_guides[id]
		var b = game.presentation.route_guides[id]
		check(a.route_points == b.route_points and a.progress == b.progress and a.material.shader == b.material.shader, "Same route geometry, timing and flow shader")
	for id in art.presentation.actors:
		var a = art.presentation.actors[id]
		var b = game.presentation.actors[id]
		check(a.position.is_equal_approx(b.position), "Matching actor grounding and flight height")
		check(a.sprite.texture == b.sprite.texture and a.sprite.flip_h == b.sprite.flip_h and a.height == b.height, "Matching enemy/operator appearance and facing")
		check(a.health_image.get_data() == b.health_image.get_data(), "Matching HP, SP and duration bars")
	for key in art.hud.cards:
		check(art.hud.cards[key].button.visible == game.hud.cards[key].button.visible, "Same deployed-card visibility")
	check(art.hud.status.text == game.hud.status.text and art.hud.economy.text == game.hud.economy.text, "Same HUD readouts")
	await RenderingServer.frame_post_draw
	art.viewport.get_texture().get_image().save_png("res://temp/verification/art_shared_battle.png")
	art.hide()
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://temp/verification/game_shared_battle.png")
	art.free(); game.free()
	for frame in 3: await process_frame
	print("PRESENTATION PARITY: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
