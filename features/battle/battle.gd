extends RefCounted
## Public, scene-free facade. Commands and simulation share one authoritative state.
const Config = preload("res://features/battle/config.gd")
const Rules = preload("res://features/battle/combat.gd")
const Navigation = preload("res://features/battle/navigation.gd")
const STEP = 1.0 / 60.0
var _config: Dictionary
var _state: Dictionary
var _events: Array = []
var _accumulator = 0.0
var _next_id = 0
var _schedule: Array = []

func _init(config: Dictionary) -> void:
	_config = Config.normalize(config)
	reset()

func reset() -> void:
	_state = {"phase": "ready", "paused": false, "time": 0.0, "life": _config.life,
		"cost": _config.initial_cost, "spawned": 0, "killed": 0, "escaped": 0,
		"remaining": 0, "units": [], "enemies": [], "redeploy": {}, "wave": 0}
	_schedule.clear()
	for wave in _config.waves:
		for i in range(wave.count):
			_schedule.append({"time": wave.time + i * wave.interval, "enemy": wave.enemy,
				"route": wave.route, "wave": wave.get("number", 1), "sequence": _schedule.size()})
	_schedule.sort_custom(func(a, b): return a.time < b.time if a.time != b.time else a.sequence < b.sequence)
	_state.remaining = _schedule.size()
	for key in _config.roster: _state.redeploy[key] = 0.0
	_events.clear()
	_accumulator = 0.0
	_next_id = 0

func deploy(roster_id: String, cell: Vector2i, facing: int = 0) -> Dictionary:
	var reason = ""
	if _state.phase not in ["ready", "running"]: reason = "finished"
	elif not _config.roster.has(roster_id): reason = "unknown_unit"
	elif facing < 0 or facing > 3: reason = "invalid_facing"
	elif _state.redeploy[roster_id] > 0.000001: reason = "redeploy_cooldown"
	else:
		var spec: Dictionary = _config.roster[roster_id]
		if not _config.terrain.has(cell) or _config.terrain[cell] != spec.terrain: reason = "wrong_terrain"
		for unit in _state.units:
			if unit.roster_id == roster_id: reason = "already_deployed"
			elif unit.cell == cell: reason = "occupied"
		if reason.is_empty() and _state.units.size() >= _config.deploy_limit: reason = "deploy_limit"
		if reason.is_empty() and _state.cost + 0.000001 < spec.cost: reason = "insufficient_cost"
	if not reason.is_empty(): return _result(false, reason)
	var unit: Dictionary = _config.roster[roster_id].duplicate(true)
	_next_id += 1
	unit.merge({"id": _next_id, "order": _next_id, "roster_id": roster_id,
		"cell": cell, "position": Vector2(cell), "facing": facing, "hp": unit.max_hp,
		"cooldown": 0.0, "action": {}, "target": -1, "blocked": [], "attack_count": 0,
		"sp": unit.skill.initial_sp, "skill_left": 0.0}, true)
	_state.cost -= unit.cost
	_state.units.append(unit)
	emit("deploy", {"source": unit.id, "roster_id": roster_id, "cell": cell, "facing": facing})
	return _result(true, "", unit.id)

func retreat(unit_id: int) -> Dictionary:
	if _state.phase not in ["ready", "running"]: return _result(false, "finished")
	var unit = _unit(unit_id)
	if unit.is_empty(): return _result(false, "unknown_unit")
	_state.cost = minf(_config.cost_cap, _state.cost + floorf(unit.cost * 0.5))
	_remove_unit(unit, "retreat")
	return _result(true)

func activate_skill(unit_id: int) -> Dictionary:
	if _state.phase != "running": return _result(false, "not_running")
	var unit = _unit(unit_id)
	if unit.is_empty(): return _result(false, "unknown_unit")
	if unit.skill_left > 0.0: return _result(false, "skill_active")
	if not unit.skill.enabled: return _result(false, "no_skill")
	if unit.sp + 0.000001 < unit.skill.required: return _result(false, "insufficient_sp")
	unit.sp = 0.0
	unit.skill_left = unit.skill.duration
	emit("skill_start", {"source": unit.id, "duration": unit.skill_left})
	return _result(true)

func start() -> bool:
	if _state.phase != "ready": return false
	_state.phase = "running"
	return true

func set_paused(value: bool) -> void:
	_state.paused = value

func advance(delta: float) -> void:
	if delta <= 0.0 or _state.phase != "running" or _state.paused: return
	_accumulator += delta
	while _accumulator + 0.000001 >= STEP and _state.phase == "running":
		_accumulator -= STEP
		_tick()

func step() -> void:
	if _state.phase == "running" and _state.paused: _tick()

func snapshot() -> Dictionary:
	var copy = _state.duplicate(true)
	for unit in copy.units: unit.range_cells = Rules.range_cells(unit)
	return copy

func configuration() -> Dictionary:
	return _config.duplicate(true)

func take_events() -> Array:
	var result = _events.duplicate(true)
	_events.clear()
	return result

func find_unit(id: int) -> Dictionary:
	for unit in _state.units:
		if unit.id == id: return unit.duplicate(true)
	return {}

func find_enemy(id: int) -> Dictionary:
	for enemy in _state.enemies:
		if enemy.id == id: return enemy.duplicate(true)
	return {}

func _unit(id: int) -> Dictionary:
	for unit in _state.units:
		if unit.id == id: return unit
	return {}

func _enemy(id: int) -> Dictionary:
	for enemy in _state.enemies:
		if enemy.id == id: return enemy
	return {}

func emit(type: String, data: Dictionary = {}) -> void:
	var event = data.duplicate(true)
	event.merge({"type": type, "time": _state.time}, true)
	_events.append(event)

func _result(ok: bool, reason: String = "", id: int = -1) -> Dictionary:
	return {"ok": ok, "reason": reason, "id": id}

func _tick() -> void:
	_state.time += STEP
	_state.cost = minf(_config.cost_cap, _state.cost + _config.cost_regen * STEP)
	for key in _state.redeploy: _state.redeploy[key] = maxf(0.0, _state.redeploy[key] - STEP)
	while _state.spawned < _schedule.size() and _schedule[_state.spawned].time <= _state.time + 0.000001:
		var entry: Dictionary = _schedule[_state.spawned]
		var enemy: Dictionary = _config.enemies[entry.enemy].duplicate(true)
		_next_id += 1
		enemy.merge({"id": _next_id, "template": entry.enemy, "route": entry.route,
			"distance": 0.0, "position": _config.routes[entry.route][0], "hp": enemy.max_hp,
			"blocked_by": -1, "cooldown": 0.0, "action": {}, "target": -1}, true)
		_state.enemies.append(enemy)
		_state.spawned += 1
		_state.wave = entry.wave
		emit("spawn", {"source": enemy.id, "template": entry.enemy, "route": entry.route})
	Rules.update_timers(self)
	Rules.enemy_actions(self)
	Navigation.move(self)
	Rules.unit_actions(self)
	_cleanup()
	_state.remaining = _schedule.size() - _state.killed - _state.escaped
	if _state.life <= 0: _state.phase = "defeat"
	elif _state.spawned == _schedule.size() and _state.enemies.is_empty(): _state.phase = "victory"
	if _state.phase != "running": emit("finished", {"phase": _state.phase})

func _remove_unit(unit: Dictionary, cause: String) -> void:
	Navigation.release(self, unit)
	_state.redeploy[unit.roster_id] = unit.redeploy_time
	_state.units.erase(unit)
	emit(cause, {"source": unit.id, "roster_id": unit.roster_id})

func _cleanup() -> void:
	for unit in _state.units.duplicate():
		if unit.hp <= 0.0: _remove_unit(unit, "death")
	for enemy in _state.enemies.duplicate():
		if enemy.hp <= 0.0:
			Navigation.unblock(self, enemy)
			_state.enemies.erase(enemy)
			_state.killed += 1
			emit("death", {"source": enemy.id, "side": "enemy"})
		elif enemy.distance >= Navigation.length_of(_config.routes[enemy.route]) - 0.000001:
			Navigation.unblock(self, enemy)
			_state.enemies.erase(enemy)
			_state.escaped += 1
			_state.life = maxi(0, _state.life - enemy.leak_damage)
			emit("escape", {"source": enemy.id, "life": _state.life})
			if _state.life <= 0: break
