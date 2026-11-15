extends SceneTree

var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func run() -> void:
	root.size = Vector2i(1280, 800)
	var game = load("res://game/battle/battle_scene.tscn").instantiate()
	game.campaign_level = "scene_0202B"
	root.add_child(game)
	game.set_process(false)
	for frame in 6: await process_frame
	check(game.validation_errors.is_empty(), "chapter two battle renders without content errors")
	var catalog = preload("res://game/content/content_catalog.gd").new()
	catalog.reload()
	var appearances: Dictionary = catalog.all_appearances()
	for index in range(11, 19):
		var key := "enemy_%03d" % index
		game.presentation.clear()
		var config: Dictionary = game.configuration.duplicate(true)
		config.enemies[key] = catalog.enemies[key].stats
		config.route_warning_duration = 0.0
		config.waves = [{"time": 0.0, "enemy": key, "route": "air" if index == 13 else "upper", "count": 1, "interval": 1.0}]
		game.appearances[key] = appearances[key]
		game.presentation.configuration = config
		game.battle = preload("res://features/battle/battle.gd").new(config)
		game.battle.start()
		game.battle.advance(0.1)
		var state: Dictionary = game.battle.snapshot()
		state.enemies[0].position = Vector2(4, 2)
		game.presentation.sync(state, game.battle.take_events(), 0.0)
		var enemy: Dictionary = state.enemies[0]
		var actor = game.presentation.actors[enemy.id]
		var appearance = appearances[key]
		check(actor.sprite.texture == appearance.attack_frames()[0], key + " uses static first frame for movement")
		state.enemies[0].position.x -= 0.25
		game.presentation.sync(state, [], 0.15)
		check(not actor.sprite.flip_h, key + " faces left when moving left")
		state.enemies[0].position.x += 0.5
		game.presentation.sync(state, [], 0.15)
		check(actor.sprite.flip_h, key + " faces right when moving right")
		var event := {"type": "attack_start", "source": enemy.id, "target": -1, "from": enemy.position, "to": enemy.position + Vector2.LEFT, "friendly": false}
		game.presentation.sync(state, [event], 0.0)
		game.presentation.sync(state, [], 0.2)
		check(actor.sprite.texture == appearance.attack_frames()[2], key + " shows attack impact")
		if index == 11:
			for frame in 4: await process_frame
			await RenderingServer.frame_post_draw
			DirAccess.make_dir_recursive_absolute("res://temp/verification")
			root.get_texture().get_image().save_png("res://temp/verification/chapter_two_battle.png")
	game.free()
	print("CHAPTER TWO VISUAL: ", failures, " failures")
	quit(1 if failures else 0)
