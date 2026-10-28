extends RefCounted
## Presentation-only warning based on remaining route distance, not combat rules.
const Navigation = preload("res://features/battle/navigation.gd")
const WARNING_DISTANCE := 1.0
const BASE_COLOR := Color("63c6f5")
const WARNING_COLOR := Color("ff654d")
var routes: Dictionary
var markers: Node3D
var hud: Control
var flash_left := 0.0
var previous_time := 0.0

func _init(route_data: Dictionary, route_markers: Node3D, overlay: Control) -> void:
	routes = route_data; markers = route_markers; hud = overlay

func sync(state: Dictionary, events: Array, delta := 0.0) -> void:
	var time: float = state.time
	if time < previous_time or state.phase == "ready": flash_left = 0.0
	previous_time = time
	flash_left = maxf(0.0, flash_left - delta)
	if events.any(func(event): return event.type == "escape"): flash_left = 0.8
	var threatened := {}
	if state.phase == "running":
		for enemy in state.enemies:
			if enemy.blocked_by != -1 or not routes.has(enemy.route): continue
			var route: Array = routes[enemy.route]
			if Navigation.length_of(route) - enemy.distance <= WARNING_DISTANCE:
				threatened[Vector2i(route[-1])] = true
	for marker in markers.get_children():
		if not marker.get_meta("is_base", false): continue
		var active: bool = threatened.has(marker.get_meta("endpoint_cell"))
		var pulse := 0.5 + 0.5 * sin(time * TAU * 2.0)
		var color := BASE_COLOR.lerp(WARNING_COLOR, 0.35 + 0.65 * pulse) if active else BASE_COLOR
		for edge in marker.get_children(): edge.material_override.albedo_color = color
		marker.set_meta("threatened", active)
	hud.set_leak_warning(not threatened.is_empty(), flash_left / 0.8)
