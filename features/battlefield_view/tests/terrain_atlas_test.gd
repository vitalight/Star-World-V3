extends SceneTree

func _initialize() -> void:
	var tileset := load("res://content/terrains/terrain_003/tileset.tres") as TileSet
	var map = load("res://content/scenes/scene_001/map.tscn").instantiate()
	var layer := map.get_node("Terrain") as TileMapLayer
	layer.tile_set = tileset
	for y in 4:
		for x in 4:
			var pos := Vector2i(x, y)
			layer.set_cell(pos, 0, pos)
	var cells: Dictionary = map.cells()
	var failures := 0
	for y in 4:
		for x in 4:
			var data: Dictionary = cells[Vector2i(x, y)]
			var high := y == 0 or y == 2
			var blocked := y < 2 and x == 3
			var expected := "none" if blocked else ("high" if high else "ground")
			if data.atlas_index != y * 4 + x or data.deployment != expected or data.walkable != (not high and not blocked) or not is_equal_approx(data.height, 0.42 if high else 0.0):
				push_error("Invalid terrain data at %s: %s" % [Vector2i(x, y), data])
				failures += 1
	print("TERRAIN ATLAS: 16 cells, %d failures" % failures)
	map.free()
	quit(1 if failures else 0)
