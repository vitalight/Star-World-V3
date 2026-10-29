extends SceneTree

const MAP := preload("res://content/scenes/scene_001/map.tscn")
const CELL := 64.0

var failures := 0
var checks := 0

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(label)

func _initialize() -> void:
	var map = MAP.instantiate()
	root.add_child(map)
	check(map.errors().is_empty(), "Sample map validates: " + str(map.errors()))

	# A ground route may not cross high platforms.
	var ground := route(map, "ground_over_high", [Vector2i(0, 0), Vector2i(2, 0), Vector2i(2, 2)])
	check(not map.errors().is_empty(), "Ground route over high terrain is rejected")
	ground.free()

	# The same route is legal for flying enemies.
	var flying := route(map, "air_over_high", [Vector2i(0, 0), Vector2i(2, 0), Vector2i(2, 2)])
	flying.set_meta("flying", true)
	check(map.errors().is_empty(), "Flying route may start on a high platform: " + str(map.errors()))
	check(map.flying_routes().has("air_over_high"), "Flying routes expose their metadata to content checks")
	flying.free()

	# Flying routes may also cross blocked ground such as water.
	var water := route(map, "air_over_water", [Vector2i(5, 5), Vector2i(6, 5)])
	water.set_meta("flying", true)
	check(map.errors().is_empty(), "Flying route may cross non-walkable ground")
	water.free()

	# Bounds and missing terrain still apply to flying routes.
	var outside := route(map, "air_outside", [Vector2i(0, 0), Vector2i(10, 0)])
	outside.set_meta("flying", true)
	check(not map.errors().is_empty(), "Flying route outside bounds is rejected")
	outside.free()

	var terrain: TileMapLayer = map.get_node("Terrain")
	terrain.erase_cell(Vector2i(0, 0))
	var missing := route(map, "air_missing", [Vector2i(0, 0), Vector2i(0, 1)])
	missing.set_meta("flying", true)
	check(not map.errors().is_empty(), "Flying route needs terrain on every cell")
	missing.free()
	terrain.set_cell(Vector2i(0, 0), 0, Vector2i(0, 0))

	check(map.routes().size() == 3, "Test routes are cleaned up")
	map.free()
	print("EDITABLE MAP: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

func route(map: Node, route_name: String, cells: Array) -> Path2D:
	var path := Path2D.new()
	path.name = route_name
	var curve := Curve2D.new()
	for cell in cells:
		curve.add_point(Vector2(cell) * CELL + Vector2(CELL, CELL) / 2.0)
	path.curve = curve
	map.get_node("Routes").add_child(path)
	return path
