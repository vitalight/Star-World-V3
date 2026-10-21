extends Node2D
## Reusable display pulse; does not claim source cells form a temporal sequence.
@export var texture: Texture2D
@export var repeat: bool = true
@export var display_scale: float = 0.7
var phase: float = 0.0
var sprite: Sprite2D

func _ready() -> void:
	sprite = Sprite2D.new()
	sprite.texture = texture
	add_child(sprite)

func _process(delta: float) -> void:
	if phase < 1.4 or repeat:
		phase += delta
		if repeat and phase > 1.4:
			phase = 0.0
		var progress: float = clampf(phase / 0.7, 0.0, 1.0)
		sprite.scale = Vector2.ONE * display_scale * lerpf(0.45, 1.0, progress)
		sprite.modulate.a = sin(progress * PI) if phase < 0.7 else 0.0

func replay() -> void:
	phase = 0.0
	set_process(true)
