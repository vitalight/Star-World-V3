extends Node2D
## The caller supplies the concrete tile atlas. No combat state is owned here.
@export var atlas: Texture2D
@export var columns: int = 10
@export var rows: int = 5
@export var tile_size: float = 88.0

func _draw() -> void:
	if not atlas:
		return
	var cell: Vector2 = atlas.get_size() / 4.0
	for y in rows:
		for x in columns:
			var tile: Vector2i = Vector2i((x + y) % 4, 0 if y == 2 else 2)
			if y != 2 and (x + y) % 5 == 0:
				tile = Vector2i(0, 3)
			draw_texture_rect_region(atlas, Rect2(x * tile_size, y * tile_size, tile_size, tile_size), Rect2(Vector2(tile) * cell, cell))
			draw_rect(Rect2(x * tile_size, y * tile_size, tile_size, tile_size), Color(0.1, 0.12, 0.15, 0.22), false, 1.0)
