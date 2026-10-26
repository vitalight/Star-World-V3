@tool
extends Resource

## Columns: idle_front_left, idle_back_left, attack_front_left, attack_back_left.
@export var atlas: Texture2D:
	set(value):
		atlas = value
		_atlas_poses.clear()
@export_range(1, 4, 1) var atlas_row: int = 1:
	set(value):
		atlas_row = clampi(value, 1, 4)
		_atlas_poses.clear()

## Legacy individual textures are used when no atlas is assigned.
@export var poses: Array[Texture2D] = []:
	get:
		if atlas == null:
			return poses
		if _atlas_poses.is_empty() or _atlas_size != atlas.get_size():
			_build_atlas_poses()
		return _atlas_poses
## Defaults to the selected row's front idle pose when not explicitly assigned.
@export var portrait: Texture2D:
	set(value):
		_portrait = value
	get:
		if _portrait != null:
			return _portrait
		return poses[0] if not poses.is_empty() else null
@export var height := 1.18
@export var class_icon: Texture2D

var _atlas_poses: Array[Texture2D] = []
var _atlas_size := Vector2.ZERO
var _portrait: Texture2D

func _validate_property(property: Dictionary) -> void:
	if (property.name == "poses" and atlas != null) or (property.name == "portrait" and _portrait == null):
		property.usage = property.usage & ~PROPERTY_USAGE_STORAGE

func _build_atlas_poses() -> void:
	_atlas_poses.clear()
	_atlas_size = atlas.get_size()
	var top := roundi(_atlas_size.y * (atlas_row - 1) / 4.0)
	var bottom := roundi(_atlas_size.y * atlas_row / 4.0)
	for column in range(4):
		var left := roundi(_atlas_size.x * column / 4.0)
		var right := roundi(_atlas_size.x * (column + 1) / 4.0)
		var texture := AtlasTexture.new()
		texture.atlas = atlas
		texture.region = Rect2(left, top, right - left, bottom - top)
		texture.filter_clip = true
		_atlas_poses.append(texture)
