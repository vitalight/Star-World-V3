extends Node3D
const Field = preload("res://features/battlefield_view/editable_field.gd")
const Stage = preload("res://features/battlefield_view/battlefield_stage.gd")
var map_source: PackedScene

func _ready() -> void:
	Stage.setup_environment(self)
	var map = map_source.instantiate()
	var field = Field.new()
	field.atlas = preload("res://content/terrains/terrain_001/atlas.png")
	field.tint = map.tint
	field.configure(map.cells(), map.bounds)
	add_child(field)
	var camera := Stage.create_camera(self)
	var center := Vector3(map.bounds.size.x * 0.5 - 0.5, 0, map.bounds.size.y * 0.5 - 0.5)
	camera.position = center + Vector3(0, 18, 11)
	camera.look_at(center)
	camera.fov = 32
	map.free()
