extends SceneTree

const Catalog = preload("res://game/content/content_catalog.gd")
const Preview = preload("res://game/player/map_preview.gd")
const Battle = preload("res://game/battle/battle_scene.tscn")
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func run() -> void:
	var catalog = Catalog.new()
	check(catalog.reload().is_empty(), "catalog loads")
	for id in catalog.levels:
		var level: Dictionary = catalog.levels[id]
		if level.type != "battle": continue
		var viewport := SubViewport.new()
		viewport.size = Vector2i(1440, 900)
		root.add_child(viewport)
		var world = Preview.new()
		world.map_source = load(level.map)
		viewport.add_child(world)
		var battle_viewport := SubViewport.new()
		battle_viewport.size = viewport.size
		root.add_child(battle_viewport)
		var battle = Battle.instantiate()
		battle.campaign_level = id
		battle_viewport.add_child(battle)
		for frame in 5: await process_frame
		check(battle.validation_errors.is_empty(), id + " battle loads")
		check(world.camera.global_transform.is_equal_approx(battle.camera.global_transform) and is_equal_approx(world.camera.v_offset, battle.camera.v_offset) and is_equal_approx(world.camera.fov, battle.camera.fov), id + " preview matches battle camera")
		for x in [world.terrain_bounds.position.x - 0.5, world.terrain_bounds.end.x - 0.5]:
			for z in [world.terrain_bounds.position.y - 0.5, world.terrain_bounds.end.y - 0.5]:
				for y in [0.0, 1.4]:
					var point: Vector2 = world.camera.unproject_position(Vector3(x, y, z))
					check(Rect2(Vector2.ZERO, Vector2(viewport.size)).has_point(point), id + " terrain fits full viewport")
		viewport.queue_free()
		battle_viewport.queue_free()
	print("MAP PREVIEW: %d failures" % failures)
	quit(1 if failures else 0)
