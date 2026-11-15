extends SceneTree

var checks := 0
var failures := 0

func _initialize() -> void: call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)

func run() -> void:
	root.size = Vector2i(1280, 800)
	var game = load("res://game/battle/battle_scene.tscn").instantiate()
	game.campaign_level = "scene_0104C"
	root.add_child(game)
	game.set_process(false)
	for frame in 6: await process_frame
	check(game.validation_errors.is_empty(), "Campaign loads")
	for index in range(1, 7):
		var key := "enemy_%03d" % index
		game.presentation.clear()
		var config: Dictionary = game.configuration.duplicate(true)
		config.route_warning_duration = 0.0
		config.waves = [{"time": 0.0, "enemy": key, "route": "air" if index == 3 else "upper", "count": 1, "interval": 1.0}]
		game.presentation.configuration = config
		game.battle = load("res://features/battle/battle.gd").new(config)
		game.battle.start()
		game.battle.advance(0.1)
		var state: Dictionary = game.battle.snapshot()
		state.enemies[0].position = Vector2(4, 2)
		game.presentation.sync(state, game.battle.take_events(), 0.0)
		var enemy: Dictionary = state.enemies[0]
		var actor = game.presentation.actors[enemy.id]
		var appearance = game.appearances[key]
		var attack: Array[Texture2D] = appearance.attack_frames()
		check(attack.size() == 4, key + " has attack animation")
		check(actor.sprite.texture == appearance.poses[0], key + " walks with its static pose")
		game.presentation.sync(state, [], 0.15)
		check(actor.sprite.texture == appearance.poses[0] and actor.motion_phase > 0.0, key + " advances procedural walking")
		var paused_phase: float = actor.motion_phase
		game.presentation.sync(state, [], 0.0)
		check(actor.sprite.texture == appearance.poses[0] and actor.motion_phase == paused_phase, key + " freezes without visual time")
		var event := {"type": "attack_start", "source": enemy.id, "target": -1, "from": enemy.position, "to": enemy.position + Vector2.LEFT, "friendly": false}
		game.presentation.sync(state, [event], 0.0)
		check(actor.sprite.texture == attack[0], key + " starts attack")
		game.presentation.sync(state, [], 0.2)
		check(actor.sprite.texture == attack[2], key + " reaches attack impact")
		if index == 1:
			for frame in 4: await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://temp/verification/chapter_enemy_attack.png")
		game.presentation.sync(state, [], 0.3)
		check(actor.sprite.texture == appearance.poses[0], key + " resumes walking")
		state.enemies[0].blocked_by = 99
		game.presentation.sync(state, [], 0.0)
		check(actor.sprite.texture == appearance.poses[0], key + " stops walking when blocked")
		if index == 5:
			state.enemies[0].blocked_by = -1
			for direction in [-1, 1]:
				state.enemies[0].position += Vector2(direction * 0.25, 0)
				game.presentation.sync(state, [], 0.15)
				check(actor.sprite.flip_h == (direction > 0) and actor.sprite.texture == appearance.poses[0], "Shield guard faces its movement direction")
				for frame in 4: await process_frame
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png("res://temp/verification/shield_guard_%s.png" % ("left" if direction < 0 else "right"))
	game.free()
	print("CHAPTER ENEMY ANIMATION: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
