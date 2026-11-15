extends Node2D
## Presentation only. Pose names describe actual atlas cells, not inferred motion.
@export var frames: SpriteFrames
@export var animation: StringName = &"front_preview"
@export var display_scale: float = 0.8
@export var procedural_walk := false
var sprite: AnimatedSprite2D
var walk_phase := 0.0
var playing := true
const ACTOR_3D = preload("res://features/actor_view/actor_view_3d.gd")

func _ready() -> void:
	sprite = AnimatedSprite2D.new()
	sprite.sprite_frames = frames
	sprite.scale = Vector2.ONE * display_scale
	add_child(sprite)
	if frames:
		sprite.play(animation)

func _process(delta: float) -> void:
	if not procedural_walk or not playing: return
	walk_phase += delta
	var sway: float = ACTOR_3D.walk_sway(walk_phase)
	sprite.position.x = sway * ACTOR_3D.WALK_TRANSLATION * 100.0
	sprite.rotation = sway * ACTOR_3D.WALK_ROLL

func show_animation(name: StringName) -> void:
	animation = name
	if sprite and frames and frames.has_animation(name):
		sprite.play(name)

func set_playing(enabled: bool) -> void:
	playing = enabled
	if enabled:
		sprite.play()
	else:
		sprite.pause()

func replay() -> void:
	walk_phase = 0.0
	sprite.position = Vector2.ZERO
	sprite.rotation = 0.0
	sprite.stop()
	sprite.play()

func step() -> void:
	sprite.pause()
	sprite.frame = (sprite.frame + 1) % frames.get_frame_count(sprite.animation)
