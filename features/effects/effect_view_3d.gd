extends Node3D
## Supplied static effect texture, animated by an external presentation clock.
@export var texture: Texture2D
@export var width := 0.85
var sprite: Sprite3D
var kind := "pulse"
var origin := Vector3.ZERO
var destination := Vector3.ZERO
var oriented := false
var single_shot := false
var age := 0.0
var duration := 0.45

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

func play_once(color := Color.WHITE, seconds := 0.45) -> void:
	single_shot = true
	sprite.no_depth_test = true # Small combat accents stay readable over the cutout.
	sprite.render_priority = 10
	age = 0.0
	duration = seconds
	sprite.scale = Vector3.ONE * 0.8
	sprite.modulate = color
	sprite.modulate.a = 0.0

func play_projectile(from: Vector3, to: Vector3, seconds: float, color := Color.WHITE) -> void:
	kind = "projectile"
	origin = from; destination = to
	position = from
	oriented = true
	play_once(color, maxf(seconds, 0.016))
	sprite.modulate.a = 1.0
	_orient()

func play_slash(from: Vector3, to: Vector3, color := Color.WHITE) -> void:
	kind = "slash"
	origin = from; destination = to
	position = from + (to - from).normalized() * 0.38
	oriented = true
	play_once(color, 0.24)
	_orient()

func _orient() -> void:
	var camera := get_viewport().get_camera_3d()
	if not camera: return
	var direction := destination - origin
	var angle := atan2(direction.dot(camera.global_basis.y), direction.dot(camera.global_basis.x))
	if kind in ["projectile", "slash"]: angle += PI # Both supplied textures point left.
	sprite.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	sprite.global_basis = camera.global_basis.rotated(camera.global_basis.z, angle).scaled(sprite.scale)

func advance_visual(delta: float) -> void:
	if not single_shot: return
	age += delta
	var progress := clampf(age / duration, 0, 1)
	if kind == "projectile":
		position = origin.lerp(destination, progress)
		sprite.scale = Vector3.ONE
		sprite.modulate.a = 1.0
	else:
		sprite.scale = Vector3.ONE * lerpf(0.8, 1.25, progress)
		sprite.modulate.a = sin(progress * PI)
	if oriented: _orient()
	if age >= duration: queue_free()
