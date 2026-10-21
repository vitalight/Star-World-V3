extends AspectRatioContainer
## Preview state and presentation controls; no combat dependency.
const ACTOR = preload("res://features/actor_view/actor_view_3d.gd")
const HUD = preload("res://features/battle_hud/battle_hud_overlay.gd")
const MAP = preload("res://content/scenes/scene_001/field.tscn")
const FLASH = preload("res://features/effects/effect_view_3d.gd")
var viewport: SubViewport
var world: Node3D
var field: Node3D
var camera: Camera3D
var hud: Control
var actors: Array[Node3D] = []
var effects: Array[MeshInstance3D] = []
var flashes: Array[Node3D] = []
var active := false
var paused := false
var speed := 1.0
var phase := 0.0
var graybox := false

func _ready() -> void:
	ratio = 16.0 / 9.0
	stretch_mode = AspectRatioContainer.STRETCH_FIT
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	var body := Control.new()
	add_child(body)
	var container := SubViewportContainer.new()
	container.size = Vector2(1280, 720)
	body.add_child(container)
	body.resized.connect(func(): container.scale = body.size / Vector2(1280, 720))
	viewport = SubViewport.new()
	viewport.size = Vector2i(1280, 720)
	viewport.own_world_3d = true
	viewport.msaa_3d = Viewport.MSAA_4X
	container.add_child(viewport)
	world = Node3D.new()
	viewport.add_child(world)
	field = MAP.instantiate()
	field.graybox = graybox
	world.add_child(field)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color("33352e")
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color("c1c9ce")
	environment.environment.ambient_light_energy = 0.62
	world.add_child(environment)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-57, -32, 0)
	light.light_color = Color("ffe5b0")
	light.light_energy = 0.78
	light.shadow_enabled = true
	light.directional_shadow_max_distance = 35
	world.add_child(light)
	camera = Camera3D.new()
	camera.fov = 27
	camera.position = Vector3(4.5, 12.9, 13.5)
	world.add_child(camera)
	camera.look_at(Vector3(4.5, 0, 3.0))
	camera.current = true
	var cells := [Vector2i(5, 0), Vector2i(6, 0), Vector2i(4, 1), Vector2i(7, 2), Vector2i(8, 3), Vector2i(6, 4), Vector2i(1, 0), Vector2i(2, 2), Vector2i(1, 3), Vector2i(1, 5)]
	var portraits: Array[Texture2D] = []
	var unit_paths := [
		"characters/character_001", "characters/character_003", "characters/character_004",
		"characters/character_005", "characters/character_006", "characters/character_007",
		"characters/character_002", "enemies/character_008", "enemies/character_009", "enemies/character_010",
	]
	for i in cells.size():
		var texture: Texture2D = load("res://content/%s/portrait.tres" % unit_paths[i])
		var actor := Node3D.new()
		actor.set_script(ACTOR)
		actor.texture = texture
		actor.height = 1.18 if i < 6 else 1.02
		actor.position = Vector3(cells[i].x, field.surface_height(cells[i]) + 0.045, cells[i].y)
		world.add_child(actor)
		actors.append(actor)
		if i < 5: portraits.append(texture)
		if i < 6:
			bar(actor.position, i)
			if i in [0, 2, 4]: ring(actor.position, Color("f2db75"), 0.32)
			if i in [0, 1]:
				var status := Label3D.new()
				status.text = "✦" if i == 0 else "+"
				status.modulate = Color("a9e582")
				status.font_size = 48
				status.pixel_size = 0.006
				status.billboard = BaseMaterial3D.BILLBOARD_ENABLED
				status.position = Vector3(0, 1.35, 0)
				actor.add_child(status)
	var flash := Node3D.new()
	flash.set_script(FLASH)
	flash.texture = preload("res://content/effects/effect_001/texture.tres")
	flash.position = actors[2].position + Vector3(-0.45, 0.5, 0.1)
	world.add_child(flash)
	flashes.append(flash)
	portal(Vector3(0, 0.06, 0), Color("ec5743"))
	portal(Vector3(0, 0.06, 5), Color("ec5743"))
	portal(Vector3(9, 0.06, 0), Color("63c6f5"))
	var layer := CanvasLayer.new()
	viewport.add_child(layer)
	hud = Control.new()
	hud.set_script(HUD)
	hud.portraits = portraits
	hud.readout = {"progress": "34 / 43", "life": "5", "cost": "55", "available": "1"}
	hud.card_costs = PackedInt32Array([9, 17, 19, 26, 39])
	hud.card_symbols = PackedStringArray(["◇", "✦", "◇", "✚", "◷"])
	hud.card_cooldowns = PackedFloat32Array([0, 0, 0, 0, 18.8])
	layer.add_child(hud)
	hud.pause_requested.connect(func(): paused = not paused; sync_playback())
	hud.speed_requested.connect(func(): speed = 2.0 if speed == 1.0 else 1.0; sync_playback())
	hud.reset_speed_requested.connect(func(): speed = 1.0; sync_playback())
	hud.replay_requested.connect(replay)
	sync_playback()

func set_active(enabled: bool) -> void:
	active = enabled
	if viewport: sync_playback()

func sync_playback() -> void:
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS if active else SubViewport.UPDATE_DISABLED
	set_process(active and not paused)
	hud.set_playback(paused, speed)

func replay() -> void:
	phase = 0.0
	paused = false
	_update_effects()
	sync_playback()

func _process(delta: float) -> void:
	phase += delta * speed
	_update_effects()

func _update_effects() -> void:
	for flash in flashes:
		flash.show_phase(phase)
	for i in effects.size():
		var pulse := 1.0 + sin(phase * 2.4 + i) * 0.08
		effects[i].scale = Vector3(pulse, 1, pulse)

func emissive(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = color
	return mat

func ring(at: Vector3, color: Color, radius: float) -> void:
	var instance := MeshInstance3D.new()
	var mesh := TorusMesh.new()
	mesh.inner_radius = radius
	mesh.outer_radius = radius + 0.025
	instance.mesh = mesh
	instance.material_override = emissive(color)
	instance.position = at + Vector3(0, 0.035, 0)
	world.add_child(instance)
	effects.append(instance)

func portal(at: Vector3, color: Color) -> void:
	var material := emissive(color)
	for edge in 12:
		var instance := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		var axis := edge / 4
		mesh.size = Vector3(0.025, 0.025, 0.025)
		mesh.size[axis] = 0.85
		var offset := Vector3.ZERO
		var a := (axis + 1) % 3
		var b := (axis + 2) % 3
		offset[a] = -0.425 if edge % 4 < 2 else 0.425
		offset[b] = -0.425 if edge % 2 == 0 else 0.425
		instance.mesh = mesh
		instance.material_override = material
		instance.position = at + Vector3(0, 0.43, 0) + offset
		world.add_child(instance)

func bar(at: Vector3, index: int) -> void:
	field.block(at + Vector3(0, 0.04, 0.3), Vector3(0.65, 0.015, 0.065), emissive(Color("253334")))
	field.block(at + Vector3(-0.04, 0.052, 0.3), Vector3(0.54 - index * 0.025, 0.015, 0.045), emissive(Color("9bd8bd")))
