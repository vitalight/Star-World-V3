@tool
extends "res://features/battlefield_view/editable_field.gd"
@export var map_source: PackedScene = preload("res://content/scenes/scene_001/map.tscn")
@export_tool_button("刷新 TileMap 的 3D 预览") var refresh_preview = rebuild

func _ready() -> void:
	if cells.is_empty():
		var source = map_source.instantiate()
		configure(source.cells(), source.bounds)
		source.free()
	super._ready()

func rebuild() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	tops.clear()
	var source = ResourceLoader.load(map_source.resource_path, "", ResourceLoader.CACHE_MODE_IGNORE_DEEP).instantiate()
	configure(source.cells(), source.bounds)
	source.free()
	super._ready()