extends Node3D
## Feet-anchored cutout with externally supplied pose, health and presentation clock.
@export var texture: Texture2D
@export var height: float = 1.2
@export var foot_offset := Vector2(0, 12)
@export var tint := Color.WHITE
const SCREEN_OFFSET := Vector2(0, 20)
var compass: MeshInstance3D
var shadow: MeshInstance3D
var sprite: Sprite3D
var appearance: Resource
var flash_left := 0.0
var fade_left := -1.0
var health: Label3D
var health_bar: Sprite3D
var health_image: Image
var health_texture: ImageTexture
var last_health := -1.0
var texture_bounds := {}
var billboard_material: ShaderMaterial
var last_bars := Vector3(-1,-1,-1)
var skill_hint: Label3D
var skill_ready := false
var readiness_phase := 0.0

func _ready() -> void:
	sprite = Sprite3D.new()
	sprite.texture = texture
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	billboard_material = ShaderMaterial.new()
	billboard_material.shader = preload("res://features/actor_view/billboard_depth.gdshader")
	billboard_material.set_shader_parameter("sprite_texture", texture)
	sprite.material_override = billboard_material
	sprite.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	sprite.alpha_scissor_threshold = 0.32
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
	sprite.modulate = tint
	if texture:
		sprite.pixel_size = height / texture.get_height()
		sprite.offset = Vector2(-foot_offset.x, texture.get_height() / 2.0 - foot_offset.y)
	add_child(sprite)
	shadow = MeshInstance3D.new()
	var disk := PlaneMesh.new()
	disk.size = Vector2(0.65, 0.45)
	shadow.mesh = disk
	var material := ShaderMaterial.new()
	material.shader = preload("res://features/actor_view/contact_shadow.gdshader")
	shadow.material_override = material
	shadow.position.y = 0.012
	shadow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(shadow)
	compass = MeshInstance3D.new()
	var compass_plane := PlaneMesh.new()
	compass_plane.size = Vector2(1.05, 1.05)
	compass.mesh = compass_plane
	var compass_material := ShaderMaterial.new()
	compass_material.shader = preload("res://features/actor_view/facing_compass.gdshader")
	compass_material.render_priority = -5
	compass.material_override = compass_material
	compass.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	compass.hide()
	add_child(compass)
	health = Label3D.new()
	health.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	health.font_size = 22
	health.pixel_size = 0.004
	health.position.y = height + 0.12
	health.no_depth_test = true
	add_child(health)
	health_bar = Sprite3D.new()
	health_bar.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	health_bar.no_depth_test = true
	health_bar.pixel_size = 0.010
	health_bar.position.y = height + 0.02
	health_image = Image.create(64, 18, false, Image.FORMAT_RGBA8)
	health_texture = ImageTexture.create_from_image(health_image)
	health_bar.texture = health_texture
	health_bar.hide()
	add_child(health_bar)
	skill_hint = Label3D.new()
	skill_hint.text = "◆"
	skill_hint.font_size = 42
	skill_hint.pixel_size = 0.006
	skill_hint.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	skill_hint.no_depth_test = true
	skill_hint.render_priority = 10
	skill_hint.modulate = Color("ffe58b")
	skill_hint.outline_modulate = Color("8d5716")
	skill_hint.outline_size = 6
	skill_hint.hide()
	add_child(skill_hint)
	_process(0.0)

func _process(_delta: float) -> void:
	update_projection()

## Shift the visual anchor along its ground plane, preserving terrain/flight height.
## Simulation position remains unchanged; the offset is measured in viewport pixels.
static func projected_position(camera: Camera3D, at: Vector3) -> Vector3:
	if not camera: return at
	# Scene assembly can create actors before the camera has been fitted.
	if (camera.get_camera_transform().affine_inverse() * at).z >= -0.0001: return at
	var point := camera.unproject_position(at) + SCREEN_OFFSET
	var hit = Plane(Vector3.UP, at.y).intersects_ray(camera.project_ray_origin(point), camera.project_ray_normal(point))
	return hit if hit is Vector3 else at

func visual_position() -> Vector3:
	return projected_position(get_viewport().get_camera_3d(), global_position)

func update_projection() -> void:
	var camera := get_viewport().get_camera_3d()
	if not camera or not sprite: return
	var anchor := visual_position()
	sprite.position = to_local(anchor)
	shadow.position = to_local(anchor + Vector3.UP * 0.012)
	compass.position = to_local(anchor + Vector3.UP * 0.008)
	health.position = to_local(anchor + camera.global_basis.y * (height + 0.12))
	health_bar.position = to_local(anchor - camera.global_basis.y * 0.15)
	skill_hint.position = to_local(anchor + camera.global_basis.y * (display_height() + 0.12))

func display_height() -> float:
	if not sprite or not sprite.texture: return height
	var image_texture := sprite.texture
	if not texture_bounds.has(image_texture):
		texture_bounds[image_texture] = image_texture.get_image().get_used_rect()
	var used: Rect2i = texture_bounds[image_texture]
	return (sprite.offset.y + image_texture.get_height() * 0.5 - used.position.y) * sprite.pixel_size

func apply_state(state: Dictionary, is_enemy: bool) -> void:
	compass.visible = not is_enemy and fade_left < 0
	compass.rotation.y = -int(state.get("facing", 2)) * PI / 2.0
	if appearance and appearance.poses.size() >= 4:
		var facing := int(state.get("facing", 2))
		var attacking: bool = not state.get("action", {}).is_empty()
		var pose := (1 if facing == 3 else 0) + (2 if attacking else 0)
		if sprite.texture != appearance.poses[pose]:
			sprite.texture = appearance.poses[pose]
			billboard_material.set_shader_parameter("sprite_texture", sprite.texture)
			sprite.pixel_size = height / sprite.texture.get_height()
			sprite.offset = Vector2(-foot_offset.x, sprite.texture.get_height() / 2.0 - foot_offset.y)
		sprite.flip_h = facing == 0 # Source poses face left; mirror only for right.
	health.hide()
	health.modulate = Color("ef9681") if is_enemy else Color("a6e8c1")
	var ratio: float = clampf(state.hp / state.max_hp, 0.0, 1.0)
	var skill: Dictionary = state.get("skill", {})
	var sp_ratio := clampf(float(state.get("sp", 0.0)) / maxf(0.001, float(skill.get("required", 1.0))), 0.0, 1.0)
	var left: float = state.get("skill_left", 0.0)
	var ready: bool = not is_enemy and state.get("skill_hint_allowed", true) and not state.get("preview", false) and skill.get("enabled", false) and left <= 0 and float(state.get("sp", 0.0)) + 0.000001 >= float(skill.get("required", 1.0))
	if ready != skill_ready:
		skill_ready = ready
		readiness_phase = 0.0
		_update_skill_glow()
	var duration_ratio := clampf(left / maxf(0.001, float(skill.get("duration", 1.0))), 0.0, 1.0)
	var bars := Vector3(ratio, -1.0 if is_enemy else sp_ratio, -1.0 if is_enemy or left <= 0 else duration_ratio)
	if bars != last_bars:
		health_image.fill(Color.TRANSPARENT)
		_bar(0, ratio, Color("ef9681") if is_enemy else Color("a6e8c1"))
		if not is_enemy:
			_bar(6, sp_ratio, Color("66bafa"))
			if left > 0: _bar(12, duration_ratio, Color("ffcd75"))
		health_texture.update(health_image)
		last_bars = bars
		last_health = ratio
	health_bar.show()

func _bar(row: int, ratio: float, color: Color) -> void:
	health_image.fill_rect(Rect2i(0, row, 64, 5), Color("24302b"))
	health_image.fill_rect(Rect2i(1, row + 1, maxi(0, roundi(62 * ratio)), 3), color)

func _update_skill_glow() -> void:
	skill_hint.visible = skill_ready
	var strength := 0.72 + 0.28 * sin(readiness_phase * 4.0) if skill_ready else 0.0
	billboard_material.set_shader_parameter("readiness", strength)
	skill_hint.modulate = Color(1.0, 0.84 + 0.12 * strength, 0.35, 0.65 + 0.35 * strength)

func hit(healing := false) -> void:
	flash_left = 0.16
	sprite.modulate = Color("a5ffae") if healing else Color("ffad7f")

func depart() -> void:
	compass.hide()
	fade_left = 0.25
	skill_ready = false
	_update_skill_glow()
	sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISABLED
	health.hide()
	health_bar.hide()

func advance_visual(delta: float) -> void:
	if skill_ready:
		readiness_phase += delta
		_update_skill_glow()
	flash_left = maxf(0, flash_left - delta)
	if flash_left <= 0: sprite.modulate = tint
	if fade_left >= 0:
		fade_left = maxf(0, fade_left - delta)
		sprite.modulate.a = fade_left / 0.25
		if fade_left <= 0: queue_free()

func set_playing(_enabled: bool) -> void:
	# This view intentionally holds a supplied static pose.
	pass
