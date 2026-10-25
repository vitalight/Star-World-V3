@tool
extends Node2D
## TileMapLayer is the sole terrain source. Paths use the same local pixel space.
@export var level: Resource
@export var bounds := Rect2i(0, 0, 10, 6)
@export var tint := Color.WHITE
@export var external_level := false

func cells() -> Dictionary:
	var result := {}
	var tiles := get_node("Terrain") as TileMapLayer
	for cell in tiles.get_used_cells():
		var tile := tiles.get_cell_tile_data(cell)
		if tile:
			result[cell] = {"appearance": tile.get_custom_data("appearance"), "height": tile.get_custom_data("height"),
				"deployment": tile.get_custom_data("deployment"), "walkable": tile.get_custom_data("walkable")}
	return result

func routes() -> Dictionary:
	var result := {}
	var tiles := get_node("Terrain") as TileMapLayer
	for path in get_node("Routes").get_children():
		if not path is Path2D: continue
		var points: Array[Vector2] = []
		if path.curve:
			for i in path.curve.point_count:
				var local := tiles.to_local(path.to_global(path.curve.get_point_position(i)))
				points.append((local - Vector2(tiles.tile_set.tile_size) / 2.0) / Vector2(tiles.tile_set.tile_size))
		result[str(path.name)] = points
	return result

func errors(check_level := true) -> PackedStringArray:
	var result := PackedStringArray()
	var data := cells()
	if bounds.position != Vector2i.ZERO or bounds.size.x < 1 or bounds.size.y < 1:
		result.append("Bounds: 地图需从 (0,0) 开始且尺寸为正")
	for cell in data:
		if not bounds.has_point(cell): result.append("Terrain %s: 超出 bounds" % cell)
		if data[cell].appearance not in ["R", "H", "G", "W"] or data[cell].deployment not in ["ground", "high", "none"] or data[cell].height < 0:
			result.append("Terrain %s: TileSet 自定义数据无效" % cell)
	var paths := routes()
	if paths.is_empty(): result.append("Routes: 至少需要一条路线")
	for key in paths:
		var points: Array = paths[key]
		var curve: Curve2D = get_node("Routes").get_node(NodePath(key)).curve
		if curve:
			for i in curve.point_count:
				if not curve.get_point_in(i).is_zero_approx() or not curve.get_point_out(i).is_zero_approx():
					result.append("Route %s[%d]: 请清零曲线手柄，路线使用轴向折线" % [key, i])
		if points.size() < 2: result.append("Route %s: 至少两个点" % key)
		for i in points.size():
			var point: Vector2 = points[i]
			if not point.is_equal_approx(point.round()): result.append("Route %s[%d]: 控制点需对齐格心" % [key, i])
			if i == 0:
				_check_route_cell(result, data, key, Vector2i(point.round()))
				continue
			var previous: Vector2 = points[i - 1]
			var delta := point - previous
			if delta.is_zero_approx() or (not is_zero_approx(delta.x) and not is_zero_approx(delta.y)):
				result.append("Route %s[%d]: 线段需沿格子轴向且不可重复" % [key, i])
				continue
			var steps := ceili(maxf(absf(delta.x), absf(delta.y)))
			for step in range(steps + 1):
				_check_route_cell(result, data, key, Vector2i((previous + delta * float(step) / steps).round()))
	if check_level and not external_level:
		if level: result.append_array(level.errors(paths))
		else: result.append("Level: 未指定关卡资源")
	return result

func _check_route_cell(result: PackedStringArray, data: Dictionary, route: String, cell: Vector2i) -> void:
	if not bounds.has_point(cell) or not data.has(cell) or not data[cell].walkable:
		result.append("Route %s: %s 越界、断路或不可通行" % [route, cell])

func configuration() -> Dictionary:
	var terrain := {}
	var data := cells()
	for cell in data:
		if data[cell].deployment in ["ground", "high"]: terrain[cell] = data[cell].deployment
	return level.configuration(terrain, routes())

func _get_configuration_warnings() -> PackedStringArray:
	if not has_node("Terrain") or not has_node("Routes"): return PackedStringArray(["需要 Terrain 和 Routes 节点"])
	return errors()

func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		update_configuration_warnings()
		queue_redraw()

func _draw() -> void:
	if not Engine.is_editor_hint() or not has_node("Terrain") or not has_node("Routes"): return
	for path in get_node("Routes").get_children():
		if not path is Path2D or not path.curve: continue
		var points := PackedVector2Array()
		for i in path.curve.point_count: points.append(to_local(path.to_global(path.curve.get_point_position(i))))
		if points.size() >= 2:
			draw_polyline(points, Color(1, 0.8, 0.3, 0.8), 3)
			draw_circle(points[0], 10, Color("ed6550"))
			draw_circle(points[-1], 10, Color("70cfff"))
