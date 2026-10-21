extends RefCounted
## Short movement sweeps prevent skipping an occupied tile, including at high speed.
static func length_of(route: Array) -> float:
	var result = 0.0
	for i in range(1, route.size()): result += route[i - 1].distance_to(route[i])
	return result

static func point_at(route: Array, distance: float) -> Vector2:
	for i in range(1, route.size()):
		var segment: float = route[i - 1].distance_to(route[i])
		if distance <= segment: return route[i - 1].lerp(route[i], distance / segment)
		distance -= segment
	return route[-1]

static func unblock(b, enemy: Dictionary) -> void:
	if enemy.blocked_by == -1: return
	var unit = b._unit(enemy.blocked_by)
	if not unit.is_empty(): unit.blocked.erase(enemy.id)
	b.emit("unblock", {"source": enemy.blocked_by, "target": enemy.id})
	enemy.blocked_by = -1

static func release(b, unit: Dictionary) -> void:
	for enemy in b._state.enemies:
		if enemy.blocked_by == unit.id: unblock(b, enemy)

static func try_block(b, enemy: Dictionary) -> bool:
	if enemy.flying: return false
	for unit in b._state.units:
		if unit.hp <= 0 or unit.block <= unit.blocked.size(): continue
		var offset: Vector2 = enemy.position - unit.position
		if absf(offset.x) <= 0.5 and absf(offset.y) <= 0.5:
			enemy.blocked_by = unit.id
			unit.blocked.append(enemy.id)
			b.emit("block", {"source": unit.id, "target": enemy.id})
			return true
	return false

static func move(b) -> void:
	for enemy in b._state.enemies:
		if enemy.hp <= 0: continue
		if enemy.blocked_by != -1:
			var blocker = b._unit(enemy.blocked_by)
			if blocker.is_empty() or blocker.hp <= 0: unblock(b, enemy)
			else: continue
		if try_block(b, enemy) or not enemy.action.is_empty(): continue
		var travel: float = enemy.speed * b.STEP
		while travel > 0.000001:
			var stride = minf(0.1, travel)
			enemy.distance += stride
			enemy.position = point_at(b._config.routes[enemy.route], enemy.distance)
			travel -= stride
			if try_block(b, enemy): break
