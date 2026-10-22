extends Node3D
signal observed(state: Dictionary, events: Array)
signal exit_requested
const StageView = preload("res://features/battlefield_view/battlefield_stage.gd")
const Battle = preload("res://features/battle/battle.gd")
const Presentation = preload("res://game/adapters/battle_presentation.gd")
const Hud = preload("res://features/battle_hud/playable_hud.gd")
const Field = preload("res://content/scenes/scene_001/field.tscn")
@export var map_source: PackedScene = preload("res://content/scenes/scene_001/map.tscn")
var battle: RefCounted
var map_data: Node2D
var field: Node3D
var camera: Camera3D
var hud: Control
var presentation: RefCounted
var world: Node3D
var markers: Node3D
var overlays: Node3D
var selected_roster := ""
var selected_unit := -1
var candidate := Vector2i(-99, -99)
var facing := 2
var direction_chosen := false
var deployment_preview: Node3D
var speed := 1.0
var last_state: Dictionary = {}
var configuration: Dictionary = {}
var validation_errors := PackedStringArray()
var show_grid := false
var show_routes := false
var show_ranges := true
var appearances := {}
var overlay_signature := ""

func _ready() -> void:
	StageView.setup_environment(self)
	camera = StageView.create_camera(self)
	get_viewport().size_changed.connect(func(): fit_camera.call_deferred())
	reload_level()

func reload_level() -> void:
	if presentation: presentation.clear()
	if world: world.free()
	if map_data: map_data.free()
	if hud: hud.get_parent().free()
	presentation = null; battle = null; hud = null
	field = null; markers = null; overlays = null
	last_state = {}; configuration = {}
	selected_roster = ""; selected_unit = -1; candidate = Vector2i(-99, -99); speed = 1.0
	overlay_signature = ""
	map_data = ResourceLoader.load(map_source.resource_path, "", ResourceLoader.CACHE_MODE_IGNORE_DEEP).instantiate()
	map_data.hide()
	add_child(map_data)
	validation_errors = map_data.errors()
	world = Node3D.new(); add_child(world)
	if not validation_errors.is_empty():
		_show_error("关卡配置错误\n" + "\n".join(validation_errors))
		return
	configuration = map_data.configuration()
	battle = Battle.new(configuration)
	configuration = battle.configuration()
	field = Field.instantiate()
	field.configure(map_data.cells(), map_data.bounds)
	world.add_child(field)
	appearances.clear()
	for collection in [map_data.level.roster, map_data.level.enemies]:
		for key in collection:
			var unit = collection[key]
			var folder := "enemies" if map_data.level.enemies.has(key) else "characters"
			var path := "res://content/%s/%s/appearance.tres" % [folder, unit.content_id]
			var appearance = load(path) if ResourceLoader.exists(path) else null
			if appearance == null or appearance.poses.size() < 4:
				validation_errors.append("Appearance %s: 缺少四种姿态资源 %s" % [key, path])
			else: appearances[key] = appearance
	if not validation_errors.is_empty():
		battle = null
		_show_error("\n".join(validation_errors))
		return
	presentation = Presentation.new(world, field, appearances, configuration)
	markers = Node3D.new(); world.add_child(markers)
	StageView.route_markers(markers, configuration.routes, field)
	overlays = Node3D.new(); world.add_child(overlays)
	var layer := CanvasLayer.new(); add_child(layer)
	hud = Hud.new()
	hud.roster = configuration.roster
	hud.catalog = appearances
	layer.add_child(hud)
	hud.start_requested.connect(start)
	hud.pause_requested.connect(toggle_pause)
	hud.speed_requested.connect(func(): set_speed(2.0 if speed == 1.0 else 1.0))
	hud.replay_requested.connect(reset)
	hud.roster_selected.connect(select_roster)
	hud.roster_drag_started.connect(select_roster)
	hud.roster_drag_hovered.connect(preview_drag)
	hud.roster_dropped.connect(drop_roster)
	hud.drop_hit_test = func(_key: String, point: Vector2):
		return last_state.phase in ["ready", "running"] and pick_cell(point) != Vector2i(-99, -99)
	hud.facing_selected.connect(func(value): facing = value; direction_chosen = true; refresh())
	hud.deploy_confirmed.connect(confirm_deployment)
	hud.cancel_requested.connect(cancel_selection)
	hud.retreat_requested.connect(func(): command("retreat", [selected_unit]))
	hud.skill_requested.connect(func(): command("activate_skill", [selected_unit]))
	hud.menu_requested.connect(func():
		if exit_requested.get_connections().is_empty(): get_tree().quit()
		else: exit_requested.emit())
	refresh()
	fit_camera.call_deferred()

func _show_error(message: String) -> void:
	var layer := CanvasLayer.new(); add_child(layer)
	hud = Control.new(); layer.add_child(hud)
	var panel := PanelContainer.new(); panel.position = Vector2(30, 90)
	hud.add_child(panel)
	var label := Label.new(); label.text = message
	panel.add_child(label)

func fit_camera() -> void:
	if camera and map_data:
		StageView.fit_camera(camera, map_data.bounds, get_viewport().get_visible_rect().size)
		update_operator_anchor()

func _process(delta: float) -> void:
	if not battle: return
	var previous: float = battle.snapshot().time
	battle.advance(delta * speed)
	refresh(battle.snapshot().time - previous)

func refresh(visual_delta := 0.0) -> void:
	if not battle: return
	last_state = battle.snapshot()
	var events: Array = battle.take_events()
	presentation.sync(last_state, events, visual_delta)
	if selected_unit != -1 and battle.find_unit(selected_unit).is_empty(): selected_unit = -1
	if last_state.phase in ["victory", "defeat"]:
		selected_roster = ""; candidate = Vector2i(-99, -99)
		hud.cancel_drag()
	hud.update_state(last_state, selected_roster, selected_unit, speed, configuration.deploy_limit)
	update_operator_anchor()
	observed.emit(last_state.duplicate(true), events.duplicate(true))
	update_overlays()

func update_operator_anchor() -> void:
	if not hud or not presentation or not presentation.actors.has(selected_unit): return
	var actor = presentation.actors[selected_unit]
	hud.set_operator_anchor(camera.unproject_position(actor.visual_position() + camera.global_basis.y * actor.display_height() * 0.5))

func command(method: String, args: Array) -> Dictionary:
	if not battle: return {"ok": false, "reason": "invalid_level", "id": -1}
	var result: Dictionary = battle.callv(method, args)
	if hud:
		hud.notice.text = "操作成功" if result.ok else "无法操作：" + reason_text(result.reason)
	refresh()
	return result

func start() -> void:
	if battle:
		battle.start()
		hud.notice.text = "点击场上干员查看技能与撤退"
		refresh()

func toggle_pause() -> void:
	if battle:
		battle.set_paused(not battle.snapshot().paused)
		refresh()

func set_speed(value: float) -> void:
	speed = value
	refresh()

func step() -> void:
	if battle:
		var previous: float = battle.snapshot().time
		battle.step()
		refresh(battle.snapshot().time - previous)

func reset() -> void:
	if not battle: return
	presentation.clear()
	battle.reset()
	selected_roster = ""; selected_unit = -1; candidate = Vector2i(-99, -99); facing = 2; speed = 1.0
	hud.cancel_drag()
	hud.direction_panel.hide()
	hud.game_menu.hide()
	hud.notice.text = "点击或拖动干员卡部署"
	refresh()

func select_roster(key: String) -> void:
	if last_state.phase not in ["ready", "running"]: return
	selected_roster = key; selected_unit = -1; candidate = Vector2i(-99, -99)
	hud.direction_panel.hide()
	hud.notice.text = configuration.roster[key].name + "：" + deployment_hint(key)
	refresh()

func preview_drag(point: Vector2) -> void:
	if selected_roster.is_empty() or last_state.phase not in ["ready", "running"]: return
	candidate = pick_cell(point)
	update_overlays()

func drop_roster(key: String, point: Vector2) -> void:
	if selected_roster != key: select_roster(key)
	var cell := pick_cell(point)
	if cell == Vector2i(-99,-99): cancel_selection()
	else: select_cell(cell)

func deployment_hint(key: String) -> String:
	return "近战干员只能部署在地面" if configuration.roster[key].terrain == "ground" else "远程／医疗干员只能部署在高台"

func select_cell(cell: Vector2i) -> void:
	if not battle or last_state.phase not in ["ready", "running"]: return
	if not selected_roster.is_empty():
		candidate = cell
		var checked: Dictionary = battle.deployment_check(selected_roster, cell, facing)
		if not checked.ok:
			hud.direction_panel.hide()
			hud.notice.text = deployment_hint(selected_roster) if checked.reason == "wrong_terrain" else "无法部署：" + reason_text(checked.reason)
			refresh()
			return
		direction_chosen = false
		hud.direction_panel.show()
		hud._fit()
		hud.notice.text = "待部署：移动鼠标选择朝向，左键确认；右键取消"
	else:
		selected_unit = -1
		for unit in last_state.units:
			if unit.cell == cell: selected_unit = unit.id
	refresh()

func confirm_deployment() -> void:
	if selected_roster.is_empty() or candidate == Vector2i(-99, -99): return
	var result := command("deploy", [selected_roster, candidate, facing])
	if result.ok:
		selected_unit = -1; selected_roster = ""; candidate = Vector2i(-99, -99)
		hud.direction_panel.hide()
		refresh()

func cancel_selection() -> void:
	selected_roster = ""; selected_unit = -1; candidate = Vector2i(-99, -99)
	if hud and battle:
		hud.cancel_drag()
		hud.direction_panel.hide()
		hud.notice.text = "点击场上干员查看技能与撤退" if last_state.phase == "running" else ("准备就绪，点击开始战斗" if last_state.units.size() == configuration.roster.size() else "点击或拖动干员卡部署")
		refresh()

func aim_deployment(point: Vector2) -> void:
	if selected_roster.is_empty() or not hud.direction_panel.visible: return
	var origin := Vector3(candidate.x, field.surface_height(candidate), candidate.y)
	var anchor := camera.unproject_position(origin)
	var movement := point - anchor
	if movement.length() < 24: return
	var directions := [Vector3.RIGHT, Vector3.BACK, Vector3.LEFT, Vector3.FORWARD]
	var best := -INF
	for index in 4:
		var projected := (camera.unproject_position(origin + directions[index]) - anchor).normalized()
		var score := projected.dot(movement.normalized())
		if score > best:
			best = score
			facing = index
	direction_chosen = true
	hud.notice.text = "朝向：%s；左键确认部署，右键取消" % ["右", "下", "左", "上"][facing]
	update_overlays()

func _unhandled_input(event: InputEvent) -> void:
	if not battle: return
	if event is InputEventMouseMotion and hud.direction_panel.visible:
		aim_deployment(event.position)
	elif event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		cancel_selection()
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_RIGHT: cancel_selection()
		elif event.button_index == MOUSE_BUTTON_LEFT:
			if hud.direction_panel.visible:
				if direction_chosen: confirm_deployment()
				get_viewport().set_input_as_handled()
				return
			if selected_roster.is_empty():
				var unit_id := pick_unit(event.position)
				if unit_id != -1:
					selected_unit = unit_id
					refresh()
					return
			var cell := pick_cell(event.position)
			if cell != Vector2i(-99, -99): select_cell(cell)

func pick_cell(point: Vector2) -> Vector2i:
	var origin := camera.project_ray_origin(point)
	var direction := camera.project_ray_normal(point)
	var closest := INF
	var result := Vector2i(-99, -99)
	for cell in map_data.cells():
		var hit = Plane(Vector3.UP, field.surface_height(cell)).intersects_ray(origin, direction)
		if hit != null and absf(hit.x - cell.x) <= 0.5 and absf(hit.z - cell.y) <= 0.5:
			var distance: float = origin.distance_squared_to(hit)
			if distance < closest: closest = distance; result = cell
	return result

func pick_unit(point: Vector2) -> int:
	var closest := INF
	var result := -1
	for unit in last_state.units:
		var actor = presentation.actors.get(unit.id)
		if not is_instance_valid(actor): continue
		var feet: Vector2 = camera.unproject_position(actor.visual_position())
		var top: Vector2 = camera.unproject_position(actor.visual_position() + camera.global_basis.y * actor.display_height())
		var half_width: float = actor.sprite.texture.get_width() * actor.sprite.pixel_size * 0.5
		var side: Vector2 = camera.unproject_position(actor.visual_position() + camera.global_basis.x * half_width)
		var width: float = absf(side.x - feet.x) * 2.0
		var rect := Rect2(Vector2(top.x - width / 2, top.y), Vector2(width, feet.y - top.y))
		var distance: float = camera.global_position.distance_squared_to(actor.visual_position())
		if rect.has_point(point) and distance < closest:
			closest = distance; result = unit.id
	return result

func set_debug(grid: bool, routes: bool, ranges: bool) -> void:
	show_grid = grid; show_routes = routes; show_ranges = ranges
	update_overlays()

func update_overlays() -> void:
	if not is_instance_valid(overlays): return
	var deployable := {}
	if not selected_roster.is_empty():
		for cell in configuration.terrain:
			if battle.deployment_check(selected_roster, cell, facing).ok: deployable[cell] = true
	var inspected: Dictionary = {}
	if selected_roster.is_empty():
		for unit in last_state.units:
			if unit.id == selected_unit: inspected = unit
	var signature := str([show_grid, show_routes, show_ranges, selected_roster, candidate, facing, hud.direction_panel.visible, deployable.keys(), selected_unit, inspected.get("cell"), inspected.get("facing"), inspected.get("range_cells")])
	if signature == overlay_signature: return
	overlay_signature = signature
	for child in overlays.get_children(): child.free()
	deployment_preview = null
	if show_grid:
		for cell in map_data.cells(): _outline(cell, Color(0.6, 0.8, 0.85, 0.65))
	if show_routes:
		for route in configuration.routes.values():
			for i in range(1, route.size()):
				var a: Vector2 = route[i - 1]; var b: Vector2 = route[i]
				var steps := ceili(a.distance_to(b))
				for j in range(steps + 1): _outline(Vector2i(a.lerp(b, float(j) / steps).round()), Color("eb9864"))
	if not selected_roster.is_empty():
		for cell in deployable:
			_cell_highlight(cell, Color(0.08, 0.84, 0.34, 0.36), Color("6cf0a0"), "deployable")
	var selected: Dictionary = inspected
	if candidate != Vector2i(-99, -99) and not selected_roster.is_empty():
		var matches: bool = deployable.has(candidate)
		if matches:
			selected = configuration.roster[selected_roster].duplicate(true)
			selected.cell = candidate; selected.facing = facing
		_outline(candidate, Color("ffe38c") if matches else Color("ed786a"))
		if hud.direction_panel.visible and matches:
			var appearance = appearances[selected_roster]
			deployment_preview = Presentation.Actor.new()
			deployment_preview.appearance = appearance
			deployment_preview.texture = appearance.poses[0]
			deployment_preview.height = appearance.height
			deployment_preview.tint = Color(1, 1, 1, 0.8) if matches else Color(1, 0.5, 0.5, 0.8)
			overlays.add_child(deployment_preview)
			deployment_preview.position = presentation.position(Vector2(candidate))
			selected.hp = selected.max_hp
			selected.preview = true
			deployment_preview.apply_state(selected, false)
			deployment_preview.update_projection()
			deployment_preview.health_bar.hide()

	if (show_ranges or hud.direction_panel.visible) and not selected.is_empty():
		for cell in preload("res://features/battle/combat.gd").range_cells(selected):
			if map_data.cells().has(cell): _range_overlay(cell)

func _range_overlay(cell: Vector2i) -> void:
	_cell_highlight(cell, Color(1.0, 0.30, 0.025, 0.52), Color("ff951c"), "attack_range")

func _cell_highlight(cell: Vector2i, color: Color, border: Color, kind: String) -> void:
	var fill := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(0.90, 0.90)
	fill.mesh = plane
	fill.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = color
	material.render_priority = 2 if kind == "attack_range" else 1
	fill.material_override = material
	fill.set_meta("overlay_kind", kind)
	fill.set_meta("cell", cell)
	fill.position = Vector3(cell.x, field.surface_height(cell) + (0.020 if kind == "attack_range" else 0.018), cell.y)
	overlays.add_child(fill)
	_outline(cell, border, 0.45, 0.030 if kind == "attack_range" else 0.025)

func _outline(cell: Vector2i, color: Color, half := 0.48, height_offset := 0.025) -> void:
	var at := Vector3(cell.x, field.surface_height(cell) + height_offset, cell.y)
	for side in [-1, 1]:
		_line(at + Vector3(side * half, 0, 0), Vector3(0.025, 0.014, half * 2), color, overlays)
		_line(at + Vector3(0, 0, side * half), Vector3(half * 2, 0.014, 0.025), color, overlays)

func _line(at: Vector3, dimensions: Vector3, color: Color, parent: Node3D) -> void:
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new(); box.size = dimensions
	mesh.mesh = box
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color
	mesh.material_override = material
	mesh.position = at
	parent.add_child(mesh)

func _exit_tree() -> void:
	if presentation: presentation.clear()
	battle = null

func reason_text(reason: String) -> String:
	return {"wrong_terrain": "地形不适合该干员", "occupied": "地块已占用", "insufficient_cost": "费用不足",
		"already_deployed": "干员已部署", "deploy_limit": "达到部署上限", "redeploy_cooldown": "再部署冷却中",
		"insufficient_sp": "技力不足", "not_running": "请先开始战斗", "finished": "战斗已结束",
		"no_skill": "没有主动技能", "skill_active": "技能持续中"}.get(reason, reason)
