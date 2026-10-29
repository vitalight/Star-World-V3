extends Node3D
signal observed(state: Dictionary, events: Array)
signal exit_requested
signal continue_requested
const StageView = preload("res://features/battlefield_view/battlefield_stage.gd")
const Battle = preload("res://features/battle/battle.gd")
const Presentation = preload("res://game/adapters/battle_presentation.gd")
const LeakWarning = preload("res://game/adapters/leak_warning.gd")
const BattleAudio = preload("res://game/adapters/battle_audio.gd")
const Hud = preload("res://features/battle_hud/playable_hud.gd")
const Field = preload("res://features/battlefield_view/editable_field.gd")
const Catalog = preload("res://game/content/content_catalog.gd")
@export var map_source: PackedScene = preload("res://content/scenes/scene_001/map.tscn")
@export var campaign_level := ""
var developer_tools_enabled := false
var developer_speed_enabled := false
var replay_data: Dictionary = {}
var replay_path := ""
var replay_mode := false
var replay_actions: Array = []
var replay_index := 0
var replay_accumulator := 0.0
var replay_error := false
var replay_error_message := ""
var save_replay_button: Button
@export var operator_ids: Array[String] = []
@export var operator_roster: Resource = preload("res://content/data/game_test_roster.tres")
var battle: RefCounted
var map_data: Node2D
var field: Node3D
var camera: Camera3D
var hud: Control
var presentation: RefCounted
var leak_warning: RefCounted
var audio: Node
var battle_audio: RefCounted
var world: Node3D
var markers: Node3D
var overlays: Node3D
var selected_roster := ""
var selected_unit := -1
var candidate := Vector2i(-99, -99)
var facing := 2
var direction_chosen := false
var deployment_pending := false
var deployment_preview: Node3D
var speed := 1.0
var last_state: Dictionary = {}
var configuration: Dictionary = {}
var validation_errors := PackedStringArray()
var show_grid := false
var show_routes := false
var show_ranges := true
var appearances := {}
var skill_icons := {}
var overlay_signature := ""
var auto_start_left := 0.0

func _ready() -> void:
	StageView.setup_environment(self)
	camera = StageView.create_camera(self)
	get_viewport().size_changed.connect(func(): fit_camera.call_deferred())
	reload_level()

func reload_level() -> void:
	replay_actions.clear(); replay_index = 0; replay_accumulator = 0.0; replay_error = false; replay_error_message = ""
	if presentation: presentation.clear()
	if world: world.free()
	if map_data: map_data.free()
	if hud: hud.get_parent().free()
	presentation = null; leak_warning = null; battle = null; hud = null; battle_audio = BattleAudio.new(audio) if audio else null
	field = null; markers = null; overlays = null
	last_state = {}; configuration = {}
	selected_roster = ""; selected_unit = -1; candidate = Vector2i(-99, -99); speed = 1.0
	deployment_pending = false; direction_chosen = false
	overlay_signature = ""
	validation_errors.clear()
	var catalog = null
	if not campaign_level.is_empty():
		catalog = Catalog.new()
		catalog.reload()
		validation_errors = catalog.diagnostics(campaign_level)
		validation_errors.append_array(catalog.operator_errors(catalog.battle_operator_ids(campaign_level, operator_ids)))
		if not validation_errors.is_empty():
			_show_error("关卡配置错误\n" + "\n".join(validation_errors)); return
		map_source = load(catalog.levels[campaign_level].map)
	map_data = ResourceLoader.load(map_source.resource_path, "", ResourceLoader.CACHE_MODE_IGNORE_DEEP).instantiate()
	map_data.hide()
	add_child(map_data)
	StageView.set_background(self, map_data.background_texture)
	validation_errors = catalog.map_errors(campaign_level, map_data) if catalog else map_data.errors()
	if catalog == null:
		if operator_roster and not operator_roster.resource_path.is_empty():
			operator_roster = ResourceLoader.load(operator_roster.resource_path, "", ResourceLoader.CACHE_MODE_IGNORE_DEEP)
		if operator_roster == null: validation_errors.append("Player: 未指定干员列表")
		else: validation_errors.append_array(operator_roster.errors())
	world = Node3D.new(); add_child(world)
	if not validation_errors.is_empty():
		_show_error("关卡配置错误\n" + "\n".join(validation_errors))
		return
	configuration = catalog.configuration(campaign_level, map_data, operator_ids) if catalog else map_data.configuration()
	if catalog == null: configuration.roster = operator_roster.configuration()
	battle = Battle.new(configuration)
	configuration = battle.configuration()
	if replay_mode and (replay_data.get("version", 0) != 1 or replay_data.get("actions", null) is not Array):
		battle = null
		_show_error("回放文件无法读取。")
		return
	reset_auto_start()
	field = Field.new()
	field.atlas = map_data.terrain_atlas if map_data.terrain_atlas else preload("res://content/terrains/terrain_001/atlas.png")
	field.tint = map_data.tint
	field.perimeter_style = map_data.perimeter_style
	field.has_backdrop = map_data.background_texture != null
	field.configure(map_data.cells(), map_data.bounds)
	world.add_child(field)
	appearances.clear()
	skill_icons.clear()
	if catalog == null:
		appearances = operator_roster.appearances()
		skill_icons = operator_roster.skill_icons()
	for collection in ([] if catalog else [map_data.level.enemies]):
		for key in collection:
			var unit = collection[key]
			var path := "res://content/enemies/%s/appearance.tres" % unit.content_id
			var appearance = load(path) if ResourceLoader.exists(path) else null
			if appearance == null or appearance.poses.size() < 4:
				validation_errors.append("Appearance %s: 缺少四种姿态资源 %s" % [key, path])
			else: appearances[key] = appearance
	if catalog: appearances = catalog.appearances(campaign_level, operator_ids)
	if catalog: skill_icons = catalog.skill_icons(campaign_level, operator_ids)
	if not validation_errors.is_empty():
		battle = null
		_show_error("\n".join(validation_errors))
		return
	presentation = Presentation.new(world, field, appearances, configuration)
	markers = Node3D.new(); world.add_child(markers)
	StageView.route_markers(markers, configuration.routes, field, map_data.flying_routes(), preload("res://content/ui/battle/air_spawn_marker_v1.png"))
	overlays = Node3D.new(); world.add_child(overlays)
	var layer := CanvasLayer.new(); add_child(layer)
	hud = Hud.new()
	hud.panel_texture = preload("res://content/ui/battle/tactical_panel_v2a.png")
	hud.developer_tools_enabled = developer_tools_enabled
	hud.replay_mode = replay_mode
	hud.roster = configuration.roster
	hud.catalog = appearances
	hud.skill_icons = skill_icons
	layer.add_child(hud)
	leak_warning = LeakWarning.new(configuration.routes, markers, hud)
	hud.pause_requested.connect(toggle_pause)
	hud.speed_requested.connect(func(): set_speed(speed * 2.0 if speed < (4.0 if developer_speed_enabled else 2.0) else 1.0))
	hud.replay_requested.connect(reset)
	hud.roster_selected.connect(select_roster)
	hud.roster_drag_started.connect(select_roster)
	hud.roster_drag_ended.connect(func():
		hud.set_playback(last_state.get("paused", false), _effective_speed())
		update_overlays())
	hud.roster_drag_hovered.connect(preview_drag)
	hud.roster_dropped.connect(drop_roster)
	hud.drop_hit_test = func(_key: String, point: Vector2):
		return last_state.phase in ["ready", "running"] and pick_cell(point) != Vector2i(-99, -99)
	hud.cancel_requested.connect(cancel_selection)
	hud.retreat_requested.connect(func(): command("retreat", [selected_unit]))
	hud.skill_requested.connect(func(): command("activate_skill", [selected_unit]))
	hud.debug_victory_requested.connect(debug_victory)
	if developer_tools_enabled and not replay_mode and not replay_path.is_empty():
		save_replay_button = Button.new()
		save_replay_button.text = "保存战斗回放"
		hud.style_battle_button(save_replay_button)
		save_replay_button.custom_minimum_size = Vector2(220, 48)
		save_replay_button.pressed.connect(func(): save_replay_button.text = "已保存" if save_recording() == OK else "保存失败")
		hud.end_panel.get_child(0).add_child(save_replay_button)
	if audio: hud.ui_sound_requested.connect(func(id: String): audio.play_sfx(id))
	hud.continue_requested.connect(func():
		if not continue_requested.get_connections().is_empty(): continue_requested.emit()
		elif not exit_requested.get_connections().is_empty(): exit_requested.emit()
		else: get_tree().quit())
	hud.menu_requested.connect(func():
		if exit_requested.get_connections().is_empty(): get_tree().quit()
		else: exit_requested.emit())
	refresh()
	fit_camera.call_deferred()

func _show_error(message: String) -> void:
	var layer := CanvasLayer.new(); add_child(layer)
	hud = Control.new(); layer.add_child(hud)
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.offset_left = 30; panel.offset_right = -30
	panel.offset_top = 90; panel.offset_bottom = -30
	hud.add_child(panel)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)
	var label := Label.new(); label.text = message
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	scroll.add_child(label)

func fit_camera() -> void:
	if camera and map_data:
		StageView.fit_camera(camera, StageView.terrain_bounds(map_data.cells(), map_data.bounds), get_viewport().get_visible_rect().size)
		update_operator_anchor()

func reset_auto_start() -> void:
	# Include the existing battle-owned route warning in the three-second lead-in.
	var first_spawn := INF
	for wave in configuration.waves:
		first_spawn = minf(first_spawn, maxf(wave.time, configuration.route_warning_duration))
	auto_start_left = maxf(0.0, 3.0 - first_spawn)

func _process(delta: float) -> void:
	if not battle: return
	var elapsed := delta * _effective_speed()
	var state: Dictionary = battle.snapshot()
	if replay_mode:
		_advance_replay(elapsed)
		var visual_delta: float = battle.snapshot().time - state.time
		refresh(visual_delta, elapsed if state.phase in ["victory", "defeat"] else visual_delta)
		return
	if state.phase == "ready" and not state.paused:
		var waiting := minf(elapsed, auto_start_left)
		auto_start_left -= waiting
		elapsed -= waiting
		if auto_start_left <= 0.000001: start()
	var previous: float = battle.snapshot().time
	battle.advance(elapsed)
	var visual_delta: float = battle.snapshot().time - previous
	var feedback_delta: float = elapsed if state.phase in ["victory", "defeat"] and not state.paused else visual_delta
	refresh(visual_delta, feedback_delta)

func refresh(visual_delta := 0.0, feedback_delta := -1.0) -> void:
	if not battle: return
	last_state = battle.snapshot()
	var events: Array = battle.take_events()
	presentation.sync(last_state, events, visual_delta)
	if audio and battle_audio == null: battle_audio = BattleAudio.new(audio)
	if battle_audio: battle_audio.sync(last_state, events)
	if selected_unit != -1 and battle.find_unit(selected_unit).is_empty(): selected_unit = -1
	if last_state.phase in ["victory", "defeat"]:
		selected_roster = ""; candidate = Vector2i(-99, -99)
		deployment_pending = false; direction_chosen = false
		hud.cancel_drag()
	hud.update_state(last_state, selected_roster, selected_unit, _effective_speed(), configuration.deploy_limit)
	leak_warning.sync(last_state, events, visual_delta if feedback_delta < 0.0 else feedback_delta)
	observed.emit(last_state.duplicate(true), events.duplicate(true))
	update_overlays()
	update_operator_anchor()

func update_operator_anchor() -> void:
	if hud:
		if deployment_pending and is_instance_valid(deployment_preview):
			deployment_preview.update_projection()
			hud.set_pending_deployment(true, camera.unproject_position(deployment_preview.visual_position() + camera.global_basis.y * deployment_preview.display_height() * 0.5))
		else: hud.set_pending_deployment(false)
	if not hud or not presentation or not presentation.actors.has(selected_unit): return
	var actor = presentation.actors[selected_unit]
	hud.set_operator_anchor(camera.unproject_position(actor.visual_position() + camera.global_basis.y * actor.display_height() * 0.5))

func command(method: String, args: Array) -> Dictionary:
	if replay_mode: return {"ok": false, "reason": "replay", "id": -1}
	if not battle: return {"ok": false, "reason": "invalid_level", "id": -1}
	var result: Dictionary = battle.callv(method, args)
	if result.ok and method in ["deploy", "retreat", "activate_skill"]: _record_action(method, args)
	if hud:
		hud.set_notice("" if result.ok else reason_text(result.reason))
	refresh()
	return result

func _record_action(method: String, args: Array) -> void:
	if developer_tools_enabled and not replay_mode:
		replay_actions.append({"tick": roundi(battle.snapshot().time / Battle.STEP), "method": method, "args": args.duplicate(true)})

func save_recording() -> Error:
	if not developer_tools_enabled or replay_mode or not battle or battle.snapshot().phase not in ["victory", "defeat"] or replay_path.is_empty(): return ERR_UNAVAILABLE
	var directory := DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(replay_path.get_base_dir()))
	if directory != OK: return directory
	var temporary := replay_path + ".tmp"
	var file := FileAccess.open(temporary, FileAccess.WRITE)
	if not file: return FileAccess.get_open_error()
	file.store_var({"version": 1, "level": campaign_level, "operators": operator_ids, "actions": replay_actions})
	file.flush()
	var error := file.get_error()
	file.close()
	if error != OK:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(temporary))
		return error
	return DirAccess.rename_absolute(ProjectSettings.globalize_path(temporary), ProjectSettings.globalize_path(replay_path))

func _replay_actions_at_tick() -> void:
	var actions: Array = replay_data.actions
	var tick := roundi(battle.snapshot().time / Battle.STEP)
	while replay_index < actions.size():
		var action = actions[replay_index]
		if action is not Dictionary or action.get("tick", -1) is not int or action.get("method", "") not in ["start", "deploy", "retreat", "activate_skill", "debug_finish_victory"] or action.get("args", null) is not Array:
			_replay_fail("数据格式错误"); return
		if action.tick > tick: return
		if action.tick < tick: _replay_fail("时间顺序错误"); return
		var valid := false
		match action.method:
			"start", "debug_finish_victory": valid = action.args.is_empty()
			"retreat", "activate_skill": valid = action.args.size() == 1 and action.args[0] is int
			"deploy": valid = action.args.size() in [2, 3] and action.args[0] is String and action.args[1] is Vector2i and (action.args.size() == 2 or action.args[2] is int)
		if not valid: _replay_fail("操作参数错误"); return
		var result = battle.callv(action.method, action.args)
		if (result is bool and not result) or (result is Dictionary and not result.get("ok", false)):
			_replay_fail("%s：%s" % [action.method, reason_text(result.get("reason", "")) if result is Dictionary else "操作失败"]); return
		replay_index += 1

func _replay_fail(reason: String) -> void:
	replay_error = true
	replay_error_message = "回放失败：第 %d 条操作，%s" % [replay_index + 1, reason]

func _advance_replay(elapsed: float) -> void:
	if replay_error: return
	_replay_actions_at_tick()
	replay_accumulator += elapsed
	while not replay_error and replay_accumulator + 0.000001 >= Battle.STEP and battle.snapshot().phase == "running":
		replay_accumulator -= Battle.STEP
		battle.advance(Battle.STEP)
		_replay_actions_at_tick()
	if battle.snapshot().phase in ["victory", "defeat"] and replay_index < replay_data.actions.size() and not replay_error: _replay_fail("战斗已结束")
	if battle.snapshot().phase == "ready" and not replay_error: _replay_fail("缺少开始战斗操作")
	if replay_error: hud.set_notice(replay_error_message)

func start() -> void:
	if battle and not replay_mode:
		if battle.start(): _record_action("start", [])
		hud.set_notice("")
		refresh()

func debug_victory() -> bool:
	if replay_mode or not battle or not battle.debug_finish_victory(): return false
	_record_action("debug_finish_victory", [])
	refresh()
	return true

func toggle_pause() -> void:
	if battle and not replay_mode:
		battle.set_paused(not battle.snapshot().paused)
		refresh()

func set_speed(value: float) -> void:
	speed = clampf(value, 1.0, 4.0 if developer_speed_enabled else 2.0)
	refresh()

func _effective_speed() -> float:
	if replay_mode or not hud: return speed
	return 0.25 if deployment_pending or not hud.dragged_roster.is_empty() else speed

func step() -> void:
	if battle and not replay_mode:
		var previous: float = battle.snapshot().time
		battle.step()
		refresh(battle.snapshot().time - previous)

func reset() -> void:
	if not battle or replay_mode: return
	replay_actions.clear()
	if is_instance_valid(save_replay_button): save_replay_button.text = "保存战斗回放"
	presentation.clear()
	battle.reset()
	reset_auto_start()
	selected_roster = ""; selected_unit = -1; candidate = Vector2i(-99, -99); facing = 2; speed = 1.0
	hud.cancel_drag()
	deployment_pending = false; direction_chosen = false
	hud.game_menu.hide()
	hud.developer_panel.visible = developer_tools_enabled
	hud.set_notice("")
	refresh()

func select_roster(key: String) -> void:
	if replay_mode: return
	if last_state.phase not in ["ready", "running"]: return
	selected_roster = key; selected_unit = -1; candidate = Vector2i(-99, -99)
	hud.game_menu.hide()
	deployment_pending = false; direction_chosen = false
	hud.set_notice("")
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
	return "该干员仅限地面" if configuration.roster[key].terrain == "ground" else "该干员仅限高台"

func select_cell(cell: Vector2i) -> void:
	if replay_mode: return
	if not battle or last_state.phase not in ["ready", "running"]: return
	hud.set_notice("")
	if not selected_roster.is_empty():
		candidate = cell
		var checked: Dictionary = battle.deployment_check(selected_roster, cell, facing)
		if not checked.ok:
			deployment_pending = false; direction_chosen = false
			hud.set_notice(deployment_hint(selected_roster) if checked.reason == "wrong_terrain" else reason_text(checked.reason))
			refresh()
			return
		direction_chosen = false
		deployment_pending = true
		hud.set_notice("")
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
		deployment_pending = false; direction_chosen = false
		refresh()

func cancel_selection() -> void:
	selected_roster = ""; selected_unit = -1; candidate = Vector2i(-99, -99)
	if hud and battle:
		hud.cancel_drag()
		deployment_pending = false; direction_chosen = false
		hud.set_notice("")
		refresh()

func aim_deployment(point: Vector2) -> void:
	direction_chosen = false
	if selected_roster.is_empty() or not deployment_pending: return
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
	hud.set_notice("")
	update_overlays()
	update_operator_anchor()

func _unhandled_input(event: InputEvent) -> void:
	if not battle or replay_mode: return
	if event is InputEventMouseMotion and deployment_pending:
		aim_deployment(event.position)
	elif event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		cancel_selection()
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_RIGHT: cancel_selection()
		elif event.button_index == MOUSE_BUTTON_LEFT:
			if deployment_pending:
				aim_deployment(event.position)
				if direction_chosen: confirm_deployment()
				get_viewport().set_input_as_handled()
				return
			if not selected_roster.is_empty(): cancel_selection()
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
	var dragging: bool = hud != null and not hud.dragged_roster.is_empty()
	if not selected_roster.is_empty() and (dragging or deployment_pending):
		for cell in configuration.terrain:
			if battle.deployment_check(selected_roster, cell, facing).ok: deployable[cell] = true
	var inspected: Dictionary = {}
	if selected_roster.is_empty():
		for unit in last_state.units:
			if unit.id == selected_unit: inspected = unit
	var signature := str([show_grid, show_routes, show_ranges, selected_roster, candidate, facing, deployment_pending, dragging, deployable.keys(), selected_unit, inspected.get("cell"), inspected.get("facing"), inspected.get("range_cells")])
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
	if dragging and not selected_roster.is_empty():
		for cell in deployable:
			_cell_highlight(cell, Color(0.08, 0.84, 0.34, 0.36), Color("6cf0a0"), "deployable")
	var selected: Dictionary = inspected
	if candidate != Vector2i(-99, -99) and not selected_roster.is_empty() and (dragging or deployment_pending):
		var matches: bool = deployable.has(candidate)
		if matches:
			selected = configuration.roster[selected_roster].duplicate(true)
			selected.cell = candidate; selected.facing = facing
		_outline(candidate, Color("ffe38c") if matches else Color("ed786a"))
		if deployment_pending and matches:
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

	if (show_ranges or deployment_pending) and not selected.is_empty():
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
	battle_audio = null

func reason_text(reason: String) -> String:
	return {"wrong_terrain": "地形不适合该干员", "occupied": "地块已占用", "insufficient_cost": "费用不足",
		"already_deployed": "干员已部署", "deploy_limit": "达到部署上限", "redeploy_cooldown": "再部署冷却中",
		"insufficient_sp": "技力不足", "not_running": "请先开始战斗", "finished": "战斗已结束",
		"no_skill": "没有主动技能", "skill_active": "技能持续中"}.get(reason, reason)
