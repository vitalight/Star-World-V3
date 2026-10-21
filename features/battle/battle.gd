extends RefCounted
## Pure rules: external tuning, no scene, display, or asset dependencies.
const STEP = 1.0 / 60.0
var _config: Dictionary
var _state: Dictionary
var _events: Array = []
var _accumulator: float = 0.0
var _spawn_clock: float = 0.0
var _next_id: int = 1
var _length: float = 0.0

func _init(config: Dictionary) -> void:
	_config = config.duplicate(true)
	for i in range(1, _config.path.size()):
		_length += _config.path[i - 1].distance_to(_config.path[i])
	reset()

func reset() -> void:
	_state = {"phase": "ready", "life": _config.life, "spawned": 0, "killed": 0, "escaped": 0, "enemies": [], "units": [], "remaining": _config.count}
	_events.clear()
	_accumulator = 0.0
	_spawn_clock = 0.0
	_next_id = 1

func deploy(slot: int) -> bool:
	if _state.phase not in ["ready", "running"] or slot < 0 or slot >= _config.slots.size():
		return false
	for unit in _state.units:
		if unit.slot == slot:
			return false
	_state.units.append({"slot": slot, "position": _config.slots[slot], "cooldown": 0.0})
	return true

func start() -> bool:
	if _state.phase != "ready":
		return false
	_state.phase = "running"
	return true

func advance(delta: float) -> void:
	if delta <= 0.0 or _state.phase != "running":
		return
	_accumulator += delta
	while _accumulator + 0.000001 >= STEP and _state.phase == "running":
		_accumulator -= STEP
		_tick()

func snapshot() -> Dictionary:
	return _state.duplicate(true)

func take_events() -> Array:
	var result = _events.duplicate(true)
	_events.clear()
	return result

func _tick() -> void:
	_spawn_clock -= STEP
	if _state.spawned < _config.count and _spawn_clock <= 0.0:
		_state.enemies.append({"id": _next_id, "distance": 0.0, "position": _config.path[0], "hp": _config.enemy_hp})
		_next_id += 1
		_state.spawned += 1
		_spawn_clock += _config.spawn_interval
	for enemy in _state.enemies:
		enemy.distance += _config.enemy_speed * STEP
		enemy.position = _point_at(enemy.distance)
	for unit in _state.units:
		unit.cooldown = maxf(0.0, unit.cooldown - STEP)
		if unit.cooldown > 0.000001:
			continue
		var target: Dictionary = {}
		for enemy in _state.enemies:
			if enemy.hp > 0 and enemy.distance < _length and unit.position.distance_to(enemy.position) <= _config.attack_range:
				if target.is_empty() or enemy.distance > target.distance:
					target = enemy
		if not target.is_empty():
			target.hp -= _config.damage
			unit.cooldown = _config.attack_interval
			_events.append({"type": "attack", "from": unit.position, "to": target.position})
	for i in range(_state.enemies.size() - 1, -1, -1):
		var enemy: Dictionary = _state.enemies[i]
		if enemy.hp <= 0:
			_state.killed += 1
			_state.enemies.remove_at(i)
		elif enemy.distance >= _length:
			_state.escaped += 1
			_state.life = maxi(0, _state.life - 1)
			_state.enemies.remove_at(i)
	_state.remaining = _config.count - _state.killed - _state.escaped
	if _state.life <= 0:
		_state.phase = "defeat"
	elif _state.spawned == _config.count and _state.enemies.is_empty():
		_state.phase = "victory"

func _point_at(distance: float) -> Vector2:
	for i in range(1, _config.path.size()):
		var start_point: Vector2 = _config.path[i - 1]
		var end_point: Vector2 = _config.path[i]
		var segment: float = start_point.distance_to(end_point)
		if distance <= segment:
			return start_point.lerp(end_point, distance / segment if segment > 0.0 else 0.0)
		distance -= segment
	return _config.path[-1]
