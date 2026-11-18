extends MeshInstance3D

const DURATION := 0.28
const SHADER = preload("res://features/effects/lightning.gdshader")
var kind := "lightning"
var age := 0.0

func strike(from: Vector3, to: Vector3) -> void:
	var camera := get_viewport().get_camera_3d()
	var view_basis := camera.global_basis if camera else Basis.IDENTITY
	var span: Vector3 = global_basis * (to - from)
	var projected := Vector2(span.dot(view_basis.x), span.dot(view_basis.y))
	position = (from + to) * 0.5
	global_basis = view_basis.rotated(view_basis.z, projected.angle())
	var quad := QuadMesh.new()
	quad.size = Vector2(maxf(0.08, projected.length()), 0.72)
	mesh = quad
	var material := ShaderMaterial.new()
	material.shader = SHADER
	material.render_priority = 12
	material.set_shader_parameter("segments", clampf(roundf(projected.length() * 5.0), 4.0, 26.0))
	material_override = material
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func advance_visual(delta: float) -> void:
	age += delta
	if age >= DURATION:
		queue_free()
		return
	material_override.set_shader_parameter("progress", age / DURATION)
