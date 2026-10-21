extends Control
signal cell_clicked(cell: Vector2i)
var config: Dictionary = {}
var state: Dictionary = {}
var flashes: Array = []
var selected = -1
var _scale = 1.0
var _offset = Vector2.ZERO
const TILE = 58.0

func _ready() -> void:
	custom_minimum_size = Vector2(0, 410)
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

func cell_screen(cell: Vector2i) -> Vector2:
	return global_position + _offset + (Vector2(cell) + Vector2.ONE * 0.5) * TILE * _scale

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var point = (event.position - _offset) / (_scale * TILE)
		var cell = Vector2i(floori(point.x), floori(point.y))
		if cell.x >= 0 and cell.y >= 0 and cell.x < config.size.x and cell.y < config.size.y:
			cell_clicked.emit(cell)
			accept_event()

func _point(position: Vector2) -> Vector2:
	return (position + Vector2.ONE * 0.5) * TILE

func _draw() -> void:
	if config.is_empty(): return
	var extent = Vector2(config.size) * TILE
	_scale = minf(size.x / extent.x, size.y / extent.y)
	_offset = (size - extent * _scale) / 2
	draw_set_transform(_offset, 0, Vector2.ONE * _scale)
	draw_rect(Rect2(Vector2.ZERO, extent), Color("111e2b"))
	var font = ThemeDB.fallback_font
	for cell in config.terrain:
		var rect = Rect2(Vector2(cell) * TILE + Vector2.ONE, Vector2.ONE * (TILE - 2))
		var high: bool = config.terrain[cell] == "high"
		draw_rect(rect, Color("304356") if high else Color("253a34"))
		if high: draw_line(rect.position, rect.position + Vector2(rect.size.x, 0), Color("6a839d"), 3)
		draw_string(font, rect.position + Vector2(3, 13), "%d,%d" % [cell.x, cell.y], HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("8294a0"))
	for route_id in config.routes:
		var route: Array = config.routes[route_id]
		var points = PackedVector2Array()
		for position in route: points.append(_point(position))
		draw_polyline(points, Color(0.8, 0.65, 0.4, 0.25), 17, true)
		draw_circle(points[0], 17, Color("b25552"))
		draw_string(font, points[0] + Vector2(-6, 5), "IN", HORIZONTAL_ALIGNMENT_LEFT, -1, 12)
		draw_rect(Rect2(points[-1] - Vector2.ONE * 17, Vector2.ONE * 34), Color("428ca6"))
		draw_string(font, points[-1] + Vector2(-9, 5), "END", HORIZONTAL_ALIGNMENT_LEFT, -1, 11)
	if state.is_empty(): return
	for unit in state.units:
		if unit.id == selected:
			for cell in unit.range_cells:
				draw_rect(Rect2(Vector2(cell) * TILE, Vector2.ONE * TILE), Color(0.4, 0.9, 0.8, 0.18))
	for unit in state.units:
		var p = _point(unit.position)
		var color = Color("87de9d") if unit.role == "healer" else Color("64d8cb")
		draw_rect(Rect2(p - Vector2.ONE * 16, Vector2.ONE * 32), color)
		if unit.id == selected: draw_rect(Rect2(p - Vector2.ONE * 20, Vector2.ONE * 40), Color.WHITE, false, 2)
		var direction = Vector2.RIGHT.rotated(unit.facing * PI / 2)
		draw_line(p, p + direction * 24, Color("ffffff"), 3, true)
		draw_string(font, p + Vector2(-16, 5), unit.name, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("10212b"))
		_bar(p, unit.hp / unit.max_hp)
		draw_string(font, p + Vector2(-25, 36), "阻%d/%d 击%d" % [unit.blocked.size(), unit.block, unit.attack_count], HORIZONTAL_ALIGNMENT_LEFT, -1, 10)
		if unit.skill.enabled:
			draw_string(font, p + Vector2(-22, -33), "SP %.1f%s" % [unit.sp, " ★" if unit.skill_left > 0 else ""], HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("f7cb70"))
		if unit.target != -1:
			for target in state.enemies + state.units:
				if target.id == unit.target: draw_line(p, _point(target.position), Color(0.4, 1, 0.8, 0.4), 1, true)
	for enemy in state.enemies:
		var p = _point(enemy.position)
		if enemy.flying:
			draw_colored_polygon(PackedVector2Array([p + Vector2(0, -15), p + Vector2(16, 12), p + Vector2(-16, 12)]), Color("d6a0ed"))
		else: draw_circle(p, 13, Color("ee7b70"))
		_bar(p, enemy.hp / enemy.max_hp)
		draw_string(font, p + Vector2(-9, 5), str(enemy.id), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("251d29"))
		if enemy.blocked_by != -1:
			for unit in state.units:
				if unit.id == enemy.blocked_by: draw_line(p, _point(unit.position), Color("f4b36a"), 2, true)
		if enemy.target != -1:
			for unit in state.units:
				if unit.id == enemy.target: draw_line(p, _point(unit.position), Color("eb8c85"), 1, true)
		if not enemy.action.is_empty(): draw_arc(p, 19, 0, TAU, 24, Color("ffc778"), 2, true)
	for flash in flashes:
		var color = Color("89ec9d") if flash.type == "heal" else (Color("f9cb60") if flash.enhanced else Color("e7a0a0"))
		color.a = clampf(flash.ttl / 0.25, 0, 1)
		draw_line(_point(flash.from), _point(flash.to), color, 3, true)
		draw_string(font, _point(flash.to) + Vector2(8, -12), "%s%.0f" % ["+" if flash.type == "heal" else "-", flash.amount], HORIZONTAL_ALIGNMENT_LEFT, -1, 15, color)

func _bar(p: Vector2, ratio: float) -> void:
	draw_rect(Rect2(p + Vector2(-18, -26), Vector2(36, 4)), Color("482e3d"))
	draw_rect(Rect2(p + Vector2(-18, -26), Vector2(36 * clampf(ratio, 0, 1), 4)), Color("a8e37b"))
