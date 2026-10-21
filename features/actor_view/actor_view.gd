extends Node2D
## Presentation only. Pose names describe actual atlas cells, not inferred motion.
@export var frames: SpriteFrames
@export var animation: StringName = &"front_preview"
@export var display_scale: float = 0.8
var sprite: AnimatedSprite2D

func _ready() -> void:
	sprite = AnimatedSprite2D.new()
	sprite.sprite_frames = frames
	sprite.scale = Vector2.ONE * display_scale
	add_child(sprite)
	if frames:
		sprite.play(animation)

func show_animation(name: StringName) -> void:
	animation = name
	if sprite and frames and frames.has_animation(name):
		sprite.play(name)

func set_playing(enabled: bool) -> void:
	if enabled:
		sprite.play()
	else:
		sprite.pause()

func step() -> void:
	sprite.pause()
	sprite.frame = (sprite.frame + 1) % frames.get_frame_count(sprite.animation)
