extends RefCounted
## Shared battle framing and route-end markers; callers supply terrain and bounds.
const ENEMY_COLOR := Color("ec5743")
const BASE_COLOR := Color("63c6f5")

static func setup_environment(parent: Node3D) -> void:
	var environment := WorldEnvironment.new()
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
	var safe := Rect2(Vector2(24, 68), viewport_size - Vector2(48, 68 + bottom_clearance))
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

static func route_markers(parent: Node3D, routes: Dictionary, terrain: Node3D) -> void:
	var endpoints := {}
	for route in routes.values():
		for index in [0, -1]:
			var cell := Vector2i(route[index])
			var key := str([cell, index])
			if endpoints.has(key): continue
			endpoints[key] = true
			portal(parent, Vector3(cell.x, terrain.surface_height(cell) + 0.06, cell.y), ENEMY_COLOR if index == 0 else BASE_COLOR)

static func portal(parent: Node3D, at: Vector3, color: Color) -> void:
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
