@tool
extends "res://features/battlefield_view/battlefield_view_3d.gd"
@export var map_source: PackedScene = preload("res://content/scenes/scene_001/map.tscn")
@export_tool_button("刷新 TileMap 的 3D 预览") var refresh_preview = rebuild

func _ready() -> void:
	if cells.is_empty():
		var source = map_source.instantiate()
		configure(source.cells(), source.bounds)
		source.free()
	super._ready()
	build_perimeter()

func configure(data: Dictionary, bounds: Rect2i) -> void:
	cells = data.duplicate(true)
	layout.clear()
	for y in range(bounds.end.y):
		var row := ""
		for x in range(bounds.end.x): row += str(cells.get(Vector2i(x, y), {}).get("appearance", " "))
		layout.append(row)

func rebuild() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	tops.clear()
	cells.clear()
	var source = ResourceLoader.load(map_source.resource_path, "", ResourceLoader.CACHE_MODE_IGNORE_DEEP).instantiate()
	configure(source.cells(), source.bounds)
	source.free()
	super._ready()
	build_perimeter()

func build_perimeter() -> void:
	# Broken outpost ruins frame the terrain without enclosing it like a board.
	var stone := material(Color("96998c"))
	if not graybox:
		stone.albedo_texture = tops[14].albedo_texture
		stone.uv1_triplanar = true
		stone.uv1_world_triplanar = true
		stone.uv1_scale = Vector3(0.65, 0.65, 0.65)
	var width := layout[0].length()
	var depth := layout.size()
	for x in range(width + 2):
		var at_x := x - 1.0
		if x in [0, 1, roundi(width * 0.4), roundi(width * 0.5), width - 1, width, width + 1]: wall_cube(Vector3(at_x, 0, -1), wall_height(x), stone)
		if x in [0, 1, width - 2, width, width + 1]: wall_cube(Vector3(at_x, 0, depth), wall_height(x + width + 2), stone)
	for z in depth:
		if z in [0, depth / 3, depth - 1]: wall_cube(Vector3(-1, 0, z), wall_height(z + 24), stone)
		if z in [0, depth / 2, depth - 1]: wall_cube(Vector3(width, 0, z), wall_height(z + 30), stone)

func wall_height(index: int) -> float:
	# Most ruins match the inner platform; a few broken pillars rise slightly.
	return 0.60 if index in [4, 9, 18, 28, 33] else 0.42

func wall_cube(at: Vector3, top: float, stone: Material) -> void:
	var height := top + 0.20
	block(at + Vector3(0, height / 2.0 - 0.20, 0), Vector3(0.99, height, 0.99), stone)
