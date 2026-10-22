@tool
extends Node3D
## Externally supplied layout and materials; coordinates are cell centers on X/Z.
@export var atlas: Texture2D
@export var layout: PackedStringArray = []
@export var decorations: Array[Vector3] = []
@export var graybox := false
var cells: Dictionary = {}
var tops: Array[Material] = []
var side: StandardMaterial3D

func surface_height(cell: Vector2i) -> float:
	if not cells.is_empty(): return float(cells.get(cell, {}).get("height", 0.0))
	if cell.y < 0 or cell.y >= layout.size() or cell.x < 0 or cell.x >= layout[cell.y].length(): return 0.0
	return 0.42 if layout[cell.y][cell.x] in ["H", "G"] else 0.0

func material(color: Color) -> StandardMaterial3D:
	var result := StandardMaterial3D.new()
	result.albedo_color = color
	result.roughness = 0.95
	return result

func block(at: Vector3, dimensions: Vector3, mat: Material) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = dimensions
	instance.mesh = mesh
	instance.material_override = mat
	instance.position = at
	add_child(instance)
	return instance

func beveled_tile(at: Vector3, height: float) -> void:
	var builder := SurfaceTool.new()
	builder.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rings: Array[PackedVector3Array] = []
	for level in 3:
		var half := 0.495 if level < 2 else 0.465
		var y := -0.2 if level == 0 else height - (0.035 if level == 1 else 0.0)
		rings.append(PackedVector3Array([Vector3(-half, y, -half), Vector3(half, y, -half), Vector3(half, y, half), Vector3(-half, y, half)]))
	for level in 2:
		for corner in 4:
			var next := (corner + 1) % 4
			for vertex in [rings[level][corner], rings[level + 1][next], rings[level + 1][corner], rings[level][corner], rings[level][next], rings[level + 1][next]]:
				builder.add_vertex(vertex)
	builder.generate_normals()
	var instance := MeshInstance3D.new()
	instance.mesh = builder.commit()
	instance.material_override = side
	instance.position = at
	add_child(instance)

func _ready() -> void:
	side = material(Color("847660"))
	# Extract each region once; filtering never samples its neighbouring atlas cell.
	for index in 16:
		var mat := material(Color.WHITE)
		if atlas and not graybox:
			mat.albedo_color = Color(0.82, 0.81, 0.77)
			var source := atlas.get_image()
			var cell := Vector2i(source.get_size() / 4)
			mat.albedo_texture = ImageTexture.create_from_image(source.get_region(Rect2i(Vector2i(index % 4, index / 4) * cell + Vector2i.ONE, cell - Vector2i(2, 2))))
		else:
			mat.albedo_color = Color("c6b590")
		tops.append(mat)
	for z in layout.size():
		for x in layout[z].length():
			if not cells.is_empty() and not cells.has(Vector2i(x, z)): continue
			var symbol := layout[z][x]
			var elevation := surface_height(Vector2i(x, z))
			beveled_tile(Vector3(x, 0, z), elevation)
			var tile := (x * 3 + z) % 4
			if symbol == "R": tile = 4 + (x + z) % 4
			if symbol == "G": tile = 10
			if symbol == "W": tile = 12
			var top := MeshInstance3D.new()
			var plane := PlaneMesh.new()
			plane.size = Vector2(0.93, 0.93)
			top.mesh = plane
			top.material_override = tops[tile]
			top.position = Vector3(x, elevation + 0.002, z)
			add_child(top)
			top.rotation.y = (x + z) % 4 * PI / 2
			if symbol == "G" and not graybox:
				grass(Vector3(x, elevation + 0.04, z))
	var rubble := material(Color("4a4d48"))
	for i in decorations.size():
		var at := decorations[i]
		var stone := block(at, Vector3(0.45 + (i % 3) * 0.17, 0.35 + (i % 4) * 0.16, 0.6), rubble)
		stone.rotation = Vector3(0.08 * (i % 3), i * 0.72, 0.06 * (i % 2))
		var cap := block(at + Vector3(0, 0.19 + (i % 4) * 0.08, 0), Vector3(0.43 + (i % 3) * 0.17, 0.04, 0.58), tops[14])
		cap.rotation = stone.rotation
		if i % 5 == 0:
			var column := MeshInstance3D.new()
			var cylinder := CylinderMesh.new()
			cylinder.top_radius = 0.17
			cylinder.bottom_radius = 0.22
			cylinder.height = 0.85
			cylinder.radial_segments = 6
			column.mesh = cylinder
			column.material_override = rubble
			column.position = at + Vector3(0.3, 0.4, 0.15)
			column.rotation.z = 0.17
			add_child(column)
	var width := layout[0].length() if not layout.is_empty() else 10
	var depth := layout.size()
	block(Vector3((width - 1) / 2.0, -0.3, (depth - 1) / 2.0), Vector3(width + 40.0, 0.2, depth + 40.0), material(Color("767667")))

func grass(at: Vector3) -> void:
	# Low, separated tufts keep tactical silhouettes clear.
	# Each leaf has a central ridge and two differently oriented surfaces.
	var rng := RandomNumberGenerator.new()
	rng.seed = 6143 + int(at.x) * 7381 + int(at.z) * 1931
	var mat := material(Color.WHITE)
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.vertex_color_use_as_albedo = true
	var builder := SurfaceTool.new()
	builder.begin(Mesh.PRIMITIVE_TRIANGLES)
	for tuft in 25:
		var root := Vector3((tuft % 5 - 2) * 0.175 + rng.randf_range(-0.035, 0.035), 0, (tuft / 5 - 2) * 0.175 + rng.randf_range(-0.035, 0.035))
		var tuft_height := rng.randf_range(0.12, 0.21)
		for leaf in 5:
			var angle := leaf * TAU / 5.0 + rng.randf_range(-0.45, 0.45)
			var outward := Vector3(cos(angle), 0, sin(angle))
			var across := Vector3(-sin(angle), 0, cos(angle))
			var height := tuft_height * rng.randf_range(0.7, 1.15)
			var lean := rng.randf_range(0.05, 0.16)
			var width := rng.randf_range(0.018, 0.033)
			var color := Color("817843").lerp(Color("ac9d60"), rng.randf())
			var sections: Array[PackedVector3Array] = []
			for segment in 6:
				var t := segment / 5.0
				var center := root + outward * lean * t * t + Vector3.UP * height * (t - 0.15 * t * t)
				var spread := width * pow(maxf(sin(PI * pow(t, 0.8)), 0.0), 0.7)
				var ridge := center + outward * spread * 0.45
				sections.append(PackedVector3Array([center - across * spread, ridge, center + across * spread]))
			for segment in 5:
				for face in 2:
					builder.set_smooth_group((tuft * 5 + leaf) * 2 + face)
					var indices: Array[Vector2i] = [Vector2i(segment, face), Vector2i(segment + 1, face), Vector2i(segment + 1, face + 1), Vector2i(segment, face), Vector2i(segment + 1, face + 1), Vector2i(segment, face + 1)]
					for vertex in indices:
						var t := vertex.x / 5.0
						var shade := 0.92 if face == 0 else 1.06
						builder.set_color(Color("756638").lerp(color, 0.25 + t * 0.75) * Color(shade, shade, shade))
						builder.add_vertex(sections[vertex.x][vertex.y])
	builder.generate_normals()
	var patch := MeshInstance3D.new()
	patch.mesh = builder.commit()
	patch.material_override = mat
	patch.position = at - Vector3(0, 0.035, 0)
	# Broad leaf shadows add depth; no sparse needle-like geometry remains.
	patch.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	add_child(patch)
