extends Node3D
## A surface-following ribbon driven by snapshot progress, never wall-clock time.
var progress := 0.0
var material: ShaderMaterial
var mesh_instance: MeshInstance3D
var route_points: Array = []
func configure(route: Array, surface_height: Callable) -> void:
	route_points = route.duplicate()
	var length := 0.0
	for index in range(1, route.size()): length += Vector2(route[index]).distance_to(route[index - 1])
	var vertices := PackedVector3Array()
	var uvs := PackedVector2Array()
	var traveled := 0.0
	for index in range(1, route.size()):
		var a := Vector2(route[index - 1]); var b := Vector2(route[index])
		var distance := a.distance_to(b)
		var side := (b - a).normalized().orthogonal() * 0.16
		var steps := maxi(1, ceili(distance / 0.20))
		for step_index in steps:
			var from := float(step_index) / steps; var to := float(step_index + 1) / steps
			var p := a.lerp(b, from); var q := a.lerp(b, to)
			for corner in [Vector2(0,0), Vector2(1,0), Vector2(0,1), Vector2(0,1), Vector2(1,0), Vector2(1,1)]:
				var center: Vector2 = p if corner.x == 0 else q
				var point: Vector2 = center + side * (corner.y * 2.0 - 1.0)
				var elevation: float = surface_height.call(Vector2i(center.round()))
				vertices.append(Vector3(point.x, elevation + 0.045, point.y))
				uvs.append(Vector2((traveled + distance * (from if corner.x == 0 else to)) / maxf(length, 0.001), corner.y))
		traveled += distance
	var arrays := []; arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices; arrays[Mesh.ARRAY_TEX_UV] = uvs
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = mesh
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	material = ShaderMaterial.new()
	material.shader = preload("res://features/battlefield_view/route_guide.gdshader")
	material.set_shader_parameter("route_length", length)
	mesh_instance.material_override = material
	add_child(mesh_instance)
func set_progress(value: float) -> void:
	progress = clampf(value, 0.0, 1.0)
	material.set_shader_parameter("progress", progress)
