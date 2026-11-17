extends Node3D
const Field = preload("res://features/battlefield_view/editable_field.gd")
const Stage = preload("res://features/battlefield_view/battlefield_stage.gd")
var map_source: PackedScene
var camera: Camera3D
var terrain_bounds: Rect2i

func _ready() -> void:
	Stage.setup_environment(self)
	var map = map_source.instantiate()
	Stage.set_background(self, map.background_texture, map.backdrop_edges)
	var field = Field.new()
	field.atlas = map.terrain_atlas if map.terrain_atlas else preload("res://content/terrains/terrain_001/atlas.png")
	field.tint = map.tint
	field.perimeter_style = map.perimeter_style
	field.has_backdrop = map.background_texture != null
	field.configure(map.cells(), map.bounds)
	add_child(field)
	Stage.route_markers(self, map.routes(), field, map.flying_routes(), preload("res://content/ui/battle/air_spawn_marker_v1.png"))
	camera = Stage.create_camera(self)
	terrain_bounds = Stage.terrain_bounds(map.cells(), map.bounds)
	Stage.fit_camera(camera, terrain_bounds, get_viewport().get_visible_rect().size)
	map.free()
