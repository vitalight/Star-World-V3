extends AspectRatioContainer
## Mock snapshots use exactly the game's presentation adapter and HUD.
const Presentation = preload("res://game/adapters/battle_presentation.gd")
const StageView = preload("res://features/battlefield_view/battlefield_stage.gd")
const HUD = preload("res://features/battle_hud/playable_hud.gd")
const MAP = preload("res://content/scenes/scene_001/field.tscn")
@export var operator_roster: Resource = preload("res://content/data/test_roster.tres")
var viewport: SubViewport
var world: Node3D
var field: Node3D
var camera: Camera3D
var hud: Control
var markers: Node3D
var presentation: RefCounted
var mock_state: Dictionary
var configuration: Dictionary
var catalog := {}
var skill_icons := {}
var actors: Array[Node3D] = []
var preview_enemies: Array = []
var next_attack := 2.4
var pending_hits: Array = []
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
	var source = field.map_source.instantiate()
	field.has_backdrop = source.background_texture != null
	world.add_child(field)
	StageView.setup_environment(world)
	StageView.set_background(world, source.background_texture)
	camera = StageView.create_camera(world)
	configuration = source.configuration()
	configuration.roster = operator_roster.configuration()
	catalog = operator_roster.appearances()
	skill_icons = operator_roster.skill_icons()
	StageView.fit_camera(camera, StageView.terrain_bounds(source.cells(), source.bounds), Vector2(viewport.size))
	markers = Node3D.new(); world.add_child(markers)
	StageView.route_markers(markers, configuration.routes, field, source.flying_routes(), preload("res://content/ui/battle/air_spawn_marker_v1.png"))
	for key in source.level.enemies:
		catalog[key] = load("res://content/enemies/%s/appearance.tres" % source.level.enemies[key].content_id)
	source.free()
	_build_mock()
	presentation = Presentation.new(world, field, catalog, configuration)
	presentation.sync(mock_state, [], 0.0)
	for actor in presentation.actors.values(): actors.append(actor)
	var layer := CanvasLayer.new()
	viewport.add_child(layer)
	hud = HUD.new()
	hud.roster = configuration.roster
	hud.catalog = catalog
	hud.skill_icons = skill_icons
	layer.add_child(hud)
	hud.pause_requested.connect(func(): paused = not paused; sync_playback())
	hud.speed_requested.connect(func(): speed = 2.0 if speed == 1.0 else 1.0; sync_playback())
	hud.replay_requested.connect(replay)
	hud.reset_speed_requested.connect(func(): speed = 1.0; sync_playback())
	# Same menu and controls; only their data source differs from the game.
	hud.menu_requested.connect(func(): get_tree().change_scene_to_file("res://devtools/hub/developer_hub.tscn"))
	hud.set_notice("")
	sync_playback()

func _build_mock() -> void:
	mock_state = {"phase": "running", "paused": false, "time": 0.0, "cost": 55.0,
		"life": 5, "killed": 34, "escaped": 0, "remaining": 9, "units": [], "enemies": [], "redeploy": {}}
	var cells := {"guard": Vector2i(3,1), "tank": Vector2i(3,4), "sniper": Vector2i(5,2), "caster": Vector2i(4,3), "medic": Vector2i(4,2)}
	var index := 0
	for key in configuration.roster:
		var spec: Dictionary = configuration.roster[key]
		var unit := spec.duplicate(true)
		unit.merge({"id": index + 1, "roster_id": key, "cell": cells[key], "position": Vector2(cells[key]),
			"hp": spec.max_hp * (0.92 - index * 0.06), "sp": float(spec.skill.get("initial_sp", index)), "skill_left": 2.5 if index == 0 and spec.skill.enabled else 0.0,
			"blocked": [], "facing": 2, "action": {}}, true)
		mock_state.units.append(unit)
		mock_state.redeploy[key] = 0.0
		index += 1
	for key in configuration.enemies:
		var spec: Dictionary = configuration.enemies[key]
		var unit := spec.duplicate(true)
		var cell: Vector2i = {"soldier": Vector2i(1,1), "rifle": Vector2i(1,4), "drone": Vector2i(2,4)}[key]
		unit.merge({"id": index + 1, "template": key, "position": Vector2(cell), "hp": spec.max_hp * 0.8,
			"cell": cell, "facing": 0, "action": {}}, true)
		preview_enemies.append(unit)
		index += 1
	_update_preview_wave()

func _update_preview_wave() -> void:
	mock_state.time = phase
	mock_state.enemies = [] if phase < 2.0 else preview_enemies
	mock_state.route_warnings = []
	if phase < 2.0:
		for route in configuration.routes:
			mock_state.route_warnings.append({"id": mock_state.route_warnings.size(), "route": route, "start": 0.0, "duration": 2.0, "spawn_at": 2.0})

func set_active(enabled: bool) -> void:
	active = enabled
	if viewport: sync_playback()

func sync_playback() -> void:
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS if active else SubViewport.UPDATE_DISABLED
	set_process(active and not paused)
	mock_state.paused = paused
	hud.update_state(mock_state, "", -1, speed, configuration.deploy_limit)

func replay() -> void:
	phase = 0.0
	paused = false
	next_attack = 2.4
	pending_hits.clear()
	for source in mock_state.units + preview_enemies: source.action = {}
	_update_preview_wave()
	presentation.clear()
	presentation.sync(mock_state, [], 0.0)
	actors.clear()
	for actor in presentation.actors.values(): actors.append(actor)
	hud.game_menu.hide()
	sync_playback()

func _process(delta: float) -> void:
	phase += delta * speed
	_update_preview_wave()
	presentation.sync(mock_state, _preview_events(), delta * speed)
	actors.clear()
	for actor in presentation.actors.values(): actors.append(actor)

func _preview_events() -> Array:
	var events: Array = []
	if mock_state.enemies.is_empty(): return events
	for hit in pending_hits.duplicate():
		if hit.at <= phase:
			events.append(hit.event)
			for source in mock_state.units + mock_state.enemies:
				if source.id == hit.event.source: source.action = {}
			pending_hits.erase(hit)
	if phase >= next_attack:
		next_attack = phase + 1.4
		for source in mock_state.units + mock_state.enemies:
			var friendly: bool = source.has("roster_id")
			var key: String = source.roster_id if friendly else source.template
			if key not in ["guard", "sniper", "medic", "soldier", "rifle"]: continue
			var healing: bool = key == "medic"
			var target: Dictionary = mock_state.units[0] if not friendly or healing else mock_state.enemies[-1]
			var attack := {"type": "attack_start", "source": source.id, "target": target.id,
				"from": source.position, "to": target.position, "friendly": friendly}
			events.append(attack)
			source.action = {"target": target.id}
			var hit := attack.duplicate(true)
			hit.type = "heal" if healing else "damage"
			pending_hits.append({"at": phase + source.windup, "event": hit})
	return events

func _exit_tree() -> void:
	if presentation: presentation.clear()
