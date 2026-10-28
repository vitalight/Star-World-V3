extends SceneTree
const Scene = preload("res://game/tests/sample_battle_fixture.tscn")
var checks := 0
var failures := 0
var game: Node3D

func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)

func capture(name: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://temp/verification/motion_" + name + ".png")

func run() -> void:
	root.size = Vector2i(1280,800)
	game = Scene.instantiate()
	root.add_child(game); game.set_process(false)
	for frame in 6: await process_frame
	game.fit_camera()
	game.command("deploy", ["guard", Vector2i(3,1), 2])
	var actor = game.presentation.actors[1]
	var state: Dictionary = game.last_state.duplicate(true)
	var origin: Vector3 = actor.global_position
	var bars: Vector3 = actor.health_bar.global_position
	var compass: Transform3D = actor.compass.global_transform
	actor.advance_visual(0.6)
	check(actor.motion_mode == "idle", "Idle operator uses breathing translation")
	var offset: Vector3 = actor.sprite.global_position - actor.visual_position()
	check(offset.dot(game.camera.global_basis.y) > 0.024 and absf(offset.dot(game.camera.global_basis.x)) < 0.0001, "Breathing translates upward along camera without lateral motion")
	check(actor.global_position == origin and game.last_state == state, "Breathing never moves logical unit or changes rules")
	check(actor.health_bar.global_position == bars and actor.compass.global_transform == compass, "Bars and ground compass remain stable")
	check(actor.sprite.rotation == Vector3.ZERO and actor.sprite.scale == Vector3.ONE, "Translation keeps billboard upright and preserves scale")
	await capture("operator_idle_high")
	actor.advance_visual(1.2)
	check((actor.sprite.global_position - actor.visual_position()).dot(game.camera.global_basis.y) < -0.024, "Breathing returns downward in a smooth cycle")
	await capture("operator_idle_low")
	game.start(); game.toggle_pause()
	var transform: Transform3D = actor.sprite.global_transform
	var phase: float = actor.motion_phase
	game._process(2.0)
	check(actor.sprite.global_transform == transform and actor.motion_phase == phase, "Paused game freezes translation")
	game.toggle_pause()
	game.set_speed(2.0)
	game._process(0.1)
	check(is_equal_approx(actor.motion_phase, phase + 0.2), "Double speed advances breathing by simulation time")
	var attacking: Dictionary = game.last_state.units[0].duplicate(true)
	attacking.action = {"target": 10}
	actor.apply_state(attacking, false); actor.update_projection()
	check(actor.motion_mode.is_empty() and actor.sprite.global_position.is_equal_approx(actor.visual_position()), "Attack pose has no idle displacement")
	attacking.action = {}; attacking.preview = true
	actor.apply_state(attacking, false); actor.update_projection()
	check(actor.motion_mode.is_empty(), "Pending deployment remains stable")
	game.battle.advance(2.1); game.refresh(2.1)
	var enemy_state: Dictionary = game.last_state.enemies[0].duplicate(true)
	var enemy = game.presentation.actors[enemy_state.id]
	enemy.apply_state(enemy_state, true)
	enemy.motion_phase = 0.0
	var enemy_origin: Vector3 = enemy.position
	enemy.advance_visual(0.1375)
	var right: Vector3 = enemy.sprite.global_position - enemy.visual_position()
	check(enemy.motion_mode == "walk" and right.dot(game.camera.global_basis.x) > 0.011, "Moving enemy sways right")
	check(absf(right.dot(game.camera.global_basis.y)) < 0.0001 and enemy.position == enemy_origin, "Walking sway preserves height and route position")
	check(right.length() < 0.013 and is_equal_approx(float(enemy.billboard_material.get_shader_parameter("walk_roll")), 0.035), "Walking uses minimal translation and a small foot-pivot roll")
	await capture("enemy_walk_right")
	enemy.advance_visual(0.275)
	check((enemy.sprite.global_position - enemy.visual_position()).dot(game.camera.global_basis.x) < -0.011, "Walking enemy sways left")
	check(is_equal_approx(float(enemy.billboard_material.get_shader_parameter("walk_roll")), -0.035), "Walking roll alternates evenly in both directions")
	await capture("enemy_walk_left")
	enemy_state.blocked_by = 1
	enemy.apply_state(enemy_state, true); enemy.update_projection()
	check(enemy.motion_mode.is_empty() and enemy.sprite.global_position.is_equal_approx(enemy.visual_position()), "Blocked enemy stops walking sway")
	enemy_state.blocked_by = -1; enemy_state.action = {"target": 1}
	enemy.apply_state(enemy_state, true); enemy.update_projection()
	check(enemy.motion_mode.is_empty() and is_zero_approx(float(enemy.billboard_material.get_shader_parameter("walk_roll"))), "Attacking enemy stops walking sway and roll")
	game.reset()
	game.command("deploy", ["guard", Vector2i(3,1), 2])
	check(game.presentation.actors[1].motion_phase == 0, "Restart clears animation phase even when IDs are reused")
	game.free()
	print("ACTOR MOTION: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
