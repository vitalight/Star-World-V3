extends SceneTree
## Validate currently authored content without asserting a particular design.
const Catalog = preload("res://game/content/content_catalog.gd")

func _initialize() -> void:
	var catalog = Catalog.new()
	catalog.reload()
	var errors: PackedStringArray = catalog.errors.duplicate()
	for id in catalog.levels:
		errors.append_array(catalog.diagnostics(id))
		if catalog.levels[id].type != "battle": continue
		var scene = load(catalog.levels[id].map)
		if not scene is PackedScene: continue
		var map = scene.instantiate()
		errors.append_array(catalog.map_errors(id, map))
		map.free()
	for message in errors: push_error(message)
	print("CHAPTER AUTHORING: %d stages, %d errors" % [catalog.levels.size(), errors.size()])
	quit(1 if not errors.is_empty() else 0)
