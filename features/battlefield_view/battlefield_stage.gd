extends RefCounted
## Shared battle framing and route-end markers; callers supply terrain and bounds.
const ENEMY_COLOR := Color("ec5743")
const BASE_COLOR := Color("63c6f5")

static func terrain_bounds(cells: Dictionary, fallback: Rect2i) -> Rect2i:
	if cells.is_empty(): return fallback
	var result := Rect2i(cells.keys()[0], Vector2i.ONE)
	for cell in cells:
		result = result.expand(cell)
		result = result.expand(cell + Vector2i.ONE)
	return result

static func setup_environment(parent: Node3D) -> void:
	var environment := WorldEnvironment.new()
	environment.name = "BattleEnvironment"
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color("55584f")
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color("a8bfd8")
	environment.environment.ambient_light_energy = 0.68
	parent.add_child(environment)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-57, -32, 0)
	light.light_color = Color("ffe7bc")
	light.light_energy = 0.95
	light.shadow_enabled = true
	parent.add_child(light)

static func set_background(parent: Node3D, texture: Texture2D) -> void:
	var old := parent.get_node_or_null("BattleBackdrop")
	if old: old.free()
	var world := parent.get_node("BattleEnvironment") as WorldEnvironment
	world.environment.background_mode = Environment.BG_CANVAS if texture else Environment.BG_COLOR
	if not texture: return
	world.environment.background_canvas_max_layer = -1
	var layer := CanvasLayer.new()
	layer.name = "BattleBackdrop"
	layer.layer = -1
	parent.add_child(layer)
	var image := TextureRect.new()
	image.texture = texture
	image.modulate = Color(0.7, 0.7, 0.7, 1.0)
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(image)
	image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

static func create_camera(parent: Node3D) -> Camera3D:
	var camera := Camera3D.new()
	camera.fov = 32
	camera.current = true
	parent.add_child(camera)
	return camera

static func fit_camera(camera: Camera3D, bounds: Rect2i, viewport_size: Vector2) -> void:
	if not camera: return
	var center := Vector3(bounds.get_center().x - 0.5, 0, bounds.get_center().y - 0.5)
	var bottom_clearance := 138.0 if viewport_size.x < 1100 else 162.0
	var right_clearance := 170.0 if viewport_size.x >= 1100 else 140.0
	var safe := Rect2(Vector2(24, 68), viewport_size - Vector2(24 + right_clearance, 68 + bottom_clearance))
	var direction := Vector3(0, 18.0, 11.0).normalized()
	for distance_step in range(120, 700):
		var distance := distance_step / 10.0
		camera.position = center + direction * distance
		camera.look_at(center)
		camera.v_offset = (safe.get_center().y - viewport_size.y * 0.5) * 2.0 * distance * tan(deg_to_rad(camera.fov * 0.5)) / viewport_size.y
		var fits := true
		for x in [bounds.position.x - 0.5, bounds.end.x - 0.5]:
			for z in [bounds.position.y - 0.5, bounds.end.y - 0.5]:
				for y in [0.0, 1.4]:
					if not safe.has_point(camera.unproject_position(Vector3(x, y, z))): fits = false
		if fits: break

static func route_markers(parent: Node3D, routes: Dictionary, terrain: Node3D, flying_routes := PackedStringArray(), air_texture: Texture2D = null) -> void:
	var endpoints := {}
	for route_id in routes:
		var route: Array = routes[route_id]
		for index in [0, -1]:
			var cell := Vector2i(route[index])
			var is_air: bool = index == 0 and flying_routes.has(str(route_id)) and air_texture != null
			var key := str([cell, index, is_air])
			if endpoints.has(key): continue
			endpoints[key] = true
			var at := Vector3(cell.x, terrain.surface_height(cell) + 0.06, cell.y)
			var marker := air_portal(parent, at, air_texture) if is_air else portal(parent, at, ENEMY_COLOR if index == 0 else BASE_COLOR)
			marker.set_meta("is_air", is_air)
			marker.set_meta("endpoint_cell", cell)
			marker.set_meta("is_base", index == -1)

static func portal(parent: Node3D, at: Vector3, color: Color) -> Node3D:
	var marker := Node3D.new()
	marker.position = at
	marker.set_meta("portal_color", color)
	parent.add_child(marker)
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color
	for edge in 12:
		var instance := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		var axis := edge / 4
		mesh.size = Vector3(0.025, 0.025, 0.025)
		mesh.size[axis] = 0.85
		var offset := Vector3.ZERO
		offset[(axis + 1) % 3] = -0.425 if edge % 4 < 2 else 0.425
		offset[(axis + 2) % 3] = -0.425 if edge % 2 == 0 else 0.425
		instance.mesh = mesh
		instance.material_override = material
		instance.position = Vector3(0, 0.43, 0) + offset
		marker.add_child(instance)
	return marker

static func air_portal(parent: Node3D, at: Vector3, texture: Texture2D) -> Node3D:
	var marker := Node3D.new()
	marker.position = at
	parent.add_child(marker)
	air_frame(marker, 0.36)
	air_frame(marker, 1.08)
	var icon := Sprite3D.new()
	icon.texture = texture
	icon.pixel_size = 0.0008
	icon.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	icon.shaded = false
	icon.position.y = 0.72
	marker.add_child(icon)
	return marker

static func air_frame(parent: Node3D, height: float) -> void:
	var frame := Node3D.new()
	frame.position.y = height
	parent.add_child(frame)
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = ENEMY_COLOR
	for side in 4:
		var edge := MeshInstance3D.new()
		var mesh := PlaneMesh.new()
		mesh.size = Vector2(0.65, 0.045) if side < 2 else Vector2(0.045, 0.65)
		edge.mesh = mesh
		edge.material_override = material
		edge.position = Vector3(0, 0, -0.325 if side == 0 else 0.325) if side < 2 else Vector3(-0.325 if side == 2 else 0.325, 0, 0)
		frame.add_child(edge)
