extends Control

signal slot_clicked(index: int)
var config: Dictionary
var state: Dictionary = {}
var flashes: Array = []
var _scale: float = 1.0
var _offset: Vector2 = Vector2.ZERO

func _ready() -> void:
	custom_minimum_size = Vector2(0, 430)
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var point = (event.position - _offset) / _scale
		for i in range(config.slots.size()):
			if point.distance_to(config.slots[i]) < 28.0:
				slot_clicked.emit(i)
				accept_event()
				break

func _draw() -> void:
	if config.is_empty():
		return
	_scale = minf(size.x / 920.0, size.y / 470.0)
	_offset = (size - Vector2(920, 470) * _scale) / 2.0
	draw_set_transform(_offset, 0.0, Vector2.ONE * _scale)
	draw_rect(Rect2(0, 0, 920, 470), Color("152331"))
	for x in range(20, 920, 40):
		draw_line(Vector2(x, 0), Vector2(x, 470), Color("1c2e3c"))
	for y in range(20, 470, 40):
		draw_line(Vector2(0, y), Vector2(920, y), Color("1c2e3c"))
	draw_polyline(PackedVector2Array(config.path), Color("3e4f60"), 44.0, true)
	draw_polyline(PackedVector2Array(config.path), Color("a3b3b7"), 2.0, true)
	draw_circle(config.path[0], 23, Color("b25552"))
	draw_rect(Rect2(config.path[-1] - Vector2(22, 22), Vector2(44, 44)), Color("4a9ab3"))
	var font = ThemeDB.fallback_font
	draw_string(font, config.path[0] + Vector2(-25, -38), "SPAWN", HORIZONTAL_ALIGNMENT_LEFT, -1, 16)
	draw_string(font, config.path[-1] + Vector2(-20, 50), "BASE", HORIZONTAL_ALIGNMENT_LEFT, -1, 16)
	for i in range(config.slots.size()):
		var point: Vector2 = config.slots[i]
		draw_rect(Rect2(point - Vector2(23, 23), Vector2(46, 46)), Color("467779"), false, 2)
		draw_string(font, point + Vector2(-5, 6), str(i + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 18)
	if state.is_empty():
		return
	for unit in state.units:
		draw_arc(unit.position, config.attack_range, 0, TAU, 64, Color(0.3, 0.8, 0.8, 0.16), 1.0, true)
		draw_rect(Rect2(unit.position - Vector2(15, 15), Vector2(30, 30)), Color("64d8cb"))
	for enemy in state.enemies:
		draw_circle(enemy.position, 13, Color("ee7b70"))
		draw_rect(Rect2(enemy.position + Vector2(-17, -24), Vector2(34, 5)), Color("482e3d"))
		draw_rect(Rect2(enemy.position + Vector2(-17, -24), Vector2(34.0 * enemy.hp / config.enemy_hp, 5)), Color("a8e37b"))
	for flash in flashes:
		draw_line(flash.from, flash.to, Color(0.6, 1.0, 0.8, flash.ttl / 0.14), 3, true)
