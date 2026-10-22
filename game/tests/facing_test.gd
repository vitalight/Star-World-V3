extends SceneTree
var failures := 0
var checks := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, text: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(text)
func run() -> void:
	var game = load("res://game/battle/battle_scene.tscn").instantiate()
	root.add_child(game); game.set_process(false)
	for frame in 6: await process_frame
	for key in game.configuration.roster:
		for facing in [0,1,2,3]:
			game.reset()
			var chosen := Vector2i(3,1) if game.configuration.roster[key].terrain == "ground" else Vector2i(4,2)
			var result: Dictionary = game.command("deploy", [key,chosen,facing])
			check(game.presentation.actors[result.id].sprite.flip_h == (facing == 0), key + " follows facing " + str(facing))
			var actor = game.presentation.actors[result.id]
			check(actor.compass.visible and actor.compass.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF, "Operator has ground compass: " + key)
			var pointer: Vector3 = actor.compass.basis.x
			var expected: Vector3 = [Vector3.RIGHT,Vector3.BACK,Vector3.LEFT,Vector3.FORWARD][facing]
			check(pointer.dot(expected) > 0.999, "Compass points along actual facing: " + str(facing))
			var state: Dictionary = game.battle.find_unit(result.id)
			state.action = {"target": 999}
			game.presentation.actors[result.id].apply_state(state, false)
			check(game.presentation.actors[result.id].sprite.flip_h == (facing == 0) and game.presentation.actors[result.id].sprite.texture == game.appearances[key].poses[3 if facing == 3 else 2], key + " attack pose preserves facing")
			if key == "guard":
				for frame in 4: await process_frame
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png("res://temp/verification/facing_" + str(facing) + ".png")
	for key in game.configuration.enemies:
		for reverse in [false,true]:
			game.reset()
			var config: Dictionary = game.configuration.duplicate(true)
			config.route_warning_duration = 0.0
			config.waves = [{"time":0.0,"enemy":key,"route":"upper","count":1,"interval":1.0}]
			if reverse: config.routes.upper.reverse()
			game.presentation.configuration = config
			game.battle = load("res://features/battle/battle.gd").new(config)
			game.start(); game.battle.advance(0.1); game.refresh(0.1)
			var id: int = game.last_state.enemies[0].id
			check(not game.presentation.actors[id].compass.visible, "Enemy has no operator compass")
			check(game.presentation.actors[id].sprite.flip_h == not reverse, key + " first frame matches route direction, reverse=" + str(reverse))
			game.battle.advance(0.1); game.refresh(0.1)
			check(game.presentation.actors[id].sprite.flip_h == not reverse, key + " movement keeps correct route facing")
	# Verify the requested screen displacement on all operator/enemy types and viewports.
	game.reset()
	var visual_config: Dictionary = game.configuration.duplicate(true)
	visual_config.route_warning_duration = 0.0
	visual_config.waves = []
	for key in visual_config.enemies:
		visual_config.waves.append({"time":0.0,"enemy":key,"route":"upper","count":1,"interval":1.0})
	game.presentation.configuration = visual_config
	game.battle = load("res://features/battle/battle.gd").new(visual_config)
	for args in preload("res://game/tests/defense_fixture.gd").deployments(): game.command("deploy",args)
	game.start(); game.battle.advance(0.1); game.refresh(0.1)
	for dimensions in [Vector2i(1280,800),Vector2i(960,600),Vector2i(1600,900)]:
		root.size = dimensions
		for frame in 6: await process_frame
		game.fit_camera()
		for actor in game.presentation.actors.values():
			actor.update_projection()
			var displacement: Vector2 = game.camera.unproject_position(actor.sprite.global_position) - game.camera.unproject_position(actor.global_position)
			check(displacement.distance_to(Vector2(0,20)) < 0.05, "Actor is lowered by 20 screen pixels: " + str(dimensions))
			check(is_equal_approx(actor.visual_position().y,actor.global_position.y), "Presentation shift preserves terrain/flight height")
			check(actor.compass.global_position.distance_to(actor.visual_position() + Vector3.UP * 0.008) < 0.001, "Compass remains centered beneath the visual feet after resize")
		for unit in game.last_state.units:
			var actor = game.presentation.actors[unit.id]
			var center: Vector2 = game.camera.unproject_position(actor.visual_position() + game.camera.global_basis.y * actor.display_height() * 0.5)
			check(game.pick_unit(center) == unit.id, "Picking follows lowered operator at " + str(dimensions))
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://temp/verification/actor_lowered_%dx%d.png" % [dimensions.x,dimensions.y])
	game.free()
	print("FACING: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
