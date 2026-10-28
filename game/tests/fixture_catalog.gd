extends "res://game/content/content_catalog.gd"
## Permit test-owned maps while preserving production resource checks elsewhere.

func _resource(row: Dictionary, field: String) -> void:
	var path: String = row[field]
	if field != "map" or not path.begins_with("res://game/tests/fixtures/chapter/"):
		super._resource(row, field)
		return
	var scene = load(path) if ResourceLoader.exists(path) else null
	if not scene is PackedScene:
		_error(row, field, "测试地图场景不存在")
		return
	var map = scene.instantiate()
	if not map.has_method("cells") or not map.has_method("errors") or not map.has_method("routes") or not map.get_node_or_null("Terrain") is TileMapLayer or map.get_node_or_null("Routes") == null:
		_error(row, field, "需要 EditableMap、Terrain 和 Routes")
	map.free()
