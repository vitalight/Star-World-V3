extends Node3D
## Supplied static effect texture, animated by an external presentation clock.
@export var texture: Texture2D
@export var width := 0.85
var sprite: Sprite3D

func _ready() -> void:
	sprite = Sprite3D.new()
	sprite.texture = texture
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.no_depth_test = false
	sprite.shaded = false
	if texture: sprite.pixel_size = width / texture.get_width()
	add_child(sprite)
	show_phase(0.0)

func show_phase(time: float) -> void:
	var cycle := fposmod(time, 2.8)
	var progress := clampf(cycle / 0.65, 0.0, 1.0)
	sprite.scale = Vector3.ONE * lerpf(0.5, 1.2, progress)
	sprite.modulate.a = sin(progress * PI) * 0.85 if cycle < 0.65 else 0.0
