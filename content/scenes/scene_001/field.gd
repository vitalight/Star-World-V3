extends "res://features/battlefield_view/battlefield_view_3d.gd"
const COMPOSITION = preload("res://content/scenes/scene_001/composition.gd")
func _init() -> void:
	layout = PackedStringArray(COMPOSITION.LAYOUT)

func _ready() -> void:
	super._ready()
	build_perimeter()

func build_perimeter() -> void:
	# A single ring of disjoint cubes on the grid, including each corner once.
	var stone := material(Color("a7aeb8"))
	if not graybox:
		var rock: StandardMaterial3D = tops[14]
		stone.albedo_texture = rock.albedo_texture
		# Project rock onto every face at a consistent scale, including short sides.
		stone.uv1_triplanar = true
		stone.uv1_world_triplanar = true
		stone.uv1_scale = Vector3(1.15, 1.15, 1.15)
		stone.uv1_triplanar_sharpness = 12.0
	for x in 12:
		var at_x := x - 1.0
		wall_cube(Vector3(at_x, 0, -1), wall_height(x), stone)
		wall_cube(Vector3(at_x, 0, 6), wall_height(x + 12), stone)
	for z in 6:
		wall_cube(Vector3(-1, 0, z), wall_height(z + 24), stone)
		wall_cube(Vector3(10, 0, z), wall_height(z + 30), stone)

func wall_height(index: int) -> float:
	# Match the inner platform (0.42); only five of the 36 cubes rise slightly.
	return 0.60 if index in [4, 9, 18, 28, 33] else 0.42

func wall_cube(at: Vector3, top: float, stone: Material) -> void:
	var height := top + 0.20
	block(at + Vector3(0, height / 2.0 - 0.20, 0), Vector3(0.99, height, 0.99), stone)
