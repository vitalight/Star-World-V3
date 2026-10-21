extends Node3D
## A feet-anchored, depth-tested cutout. No combat state or pose inference.
@export var texture: Texture2D
@export var height: float = 1.2
@export var foot_offset := Vector2(0, 12)
@export var tint := Color.WHITE
var sprite: Sprite3D

func _ready() -> void:
	sprite = Sprite3D.new()
	sprite.texture = texture
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	sprite.alpha_scissor_threshold = 0.32
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
	sprite.modulate = tint
	if texture:
		sprite.pixel_size = height / texture.get_height()
		sprite.offset = Vector2(-foot_offset.x, texture.get_height() / 2.0 - foot_offset.y)
	add_child(sprite)
	var shadow := MeshInstance3D.new()
	var disk := PlaneMesh.new()
	disk.size = Vector2(0.65, 0.45)
	shadow.mesh = disk
	var material := ShaderMaterial.new()
	material.shader = preload("res://features/actor_view/contact_shadow.gdshader")
	shadow.material_override = material
	shadow.position.y = 0.012
	shadow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(shadow)

func set_playing(_enabled: bool) -> void:
	# This view intentionally holds a supplied static pose.
	pass
