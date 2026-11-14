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
	root.add_child(game)
	game.set_process(false)
	for frame in 6: await process_frame
	for index in range(11, 16):
		game.reset()
		var key := "character_%03d" % index
		var cell := Vector2i(4, 2) if index in [13, 15] else Vector2i(3, 1)
		var result: Dictionary = game.command("deploy", [key, cell, 0])
		check(result.ok, key + " deploys")
		if not result.ok: continue
		var actor = game.presentation.actors[result.id]
		var appearance = game.appearances[key]
		var frames: Array[Texture2D] = appearance.attack_frames()
		check(frames.size() == 4 and appearance.portrait == frames[0], key + " uses new portrait and four frames")
		var event := {"type": "attack_start", "source": result.id, "target": -1, "from": Vector2(cell), "to": Vector2(cell) + Vector2.RIGHT, "friendly": true}
		game.presentation.sync(game.battle.snapshot(), [event], 0.0)
		check(actor.sprite.texture == frames[0] and actor.sprite.flip_h, key + " starts attack facing right")
		game.presentation.sync(game.battle.snapshot(), [], 0.10)
		check(actor.sprite.texture == frames[1], key + " shows windup")
		game.presentation.sync(game.battle.snapshot(), [], 0.0)
		check(actor.sprite.texture == frames[1], key + " remains frozen without visual time")
		game.presentation.sync(game.battle.snapshot(), [], 0.10)
		check(actor.sprite.texture == frames[2], key + " shows impact")
		if index == 11:
			for frame in 4: await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://temp/verification/chapter_attack.png")
		game.presentation.sync(game.battle.snapshot(), [], 0.12)
		check(actor.sprite.texture == frames[3], key + " shows recovery")
		game.presentation.sync(game.battle.snapshot(), [], 0.14)
		check(actor.sprite.texture == frames[0], key + " returns to idle")
	game.free()
	print("CHAPTER ATTACK ANIMATION: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
