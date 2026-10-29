extends SceneTree

const Stage = preload("res://features/battlefield_view/battlefield_stage.gd")
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)

func run() -> void:
	var sparse := {Vector2i(2, 3): {}, Vector2i(5, 6): {}}
	check(Stage.terrain_bounds(sparse, Rect2i(0, 0, 10, 10)) == Rect2i(2, 3, 4, 4), "Framing includes sparse cells and their offset")
	check(Stage.terrain_bounds({}, Rect2i(0, 0, 10, 6)) == Rect2i(0, 0, 10, 6), "Empty terrain uses the authored bounds")
	var game = load("res://game/battle/battle_scene.tscn").instantiate()
	game.campaign_level = "scene_0102B"
	root.add_child(game)
	for frame in 8: await process_frame
	check(game.validation_errors.is_empty(), "02B loads")
	check(game.field.terrain_rect == Rect2i(0, 0, 9, 5), "02B perimeter follows its actual 9 by 5 terrain")
	for dimensions in [Vector2i(1280, 800), Vector2i(960, 600), Vector2i(1600, 900)]:
		root.size = dimensions
		for frame in 4: await process_frame
		game.fit_camera()
		for cell in game.map_data.cells():
			var at := Vector3(cell.x, game.field.surface_height(cell), cell.y)
			var point: Vector2 = game.camera.unproject_position(at)
			check(root.get_visible_rect().has_point(point), "Cell remains visible at %s: %s" % [dimensions, cell])
			check(game.pick_cell(point) == cell, "Picking follows framing at %s: %s" % [dimensions, cell])
		if dimensions == Vector2i(1280, 800):
			DirAccess.make_dir_recursive_absolute("res://temp/verification")
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://temp/verification/scene_0102b_framing.png")
	game.queue_free()
	print("BATTLE FRAMING: %d failures" % failures)
	quit(1 if failures else 0)
