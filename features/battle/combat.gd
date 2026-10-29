extends RefCounted
## Targeting, attack actions, damage/healing and skill clocks; no display dependency.
const Navigation = preload("res://features/battle/navigation.gd")

static func range_cells(unit: Dictionary) -> Array:
	var cells: Array = []
	var offsets: Array = unit.range.duplicate()
	if unit.get("skill_left", 0.0) > 0 and unit.skill.forward_range > 0 and not offsets.is_empty():
		var front: int = offsets.map(func(offset): return Vector2i(offset).x).max()
		for offset in unit.range:
			if Vector2i(offset).x == front:
				for extra in range(1, unit.skill.forward_range + 1): offsets.append(Vector2i(offset) + Vector2i(extra, 0))
	for offset in offsets:
		var p = Vector2i(offset)
		for i in range(unit.facing): p = Vector2i(-p.y, p.x)
		cells.append(unit.cell + p)
	return cells

static func in_range(unit: Dictionary, position: Vector2) -> bool:
	for cell in range_cells(unit):
		var offset = position - Vector2(cell)
		if absf(offset.x) <= 0.500001 and absf(offset.y) <= 0.500001: return true
	return false

## A blocked enemy is on the incoming side of its blocker, even when its
## movement step has crossed the blocker's tile boundary by a small amount.
static func blocked_target_position(b, enemy: Dictionary, blocker: Dictionary) -> Vector2:
	var route: Array = b._config.routes[enemy.route]
	var before := Navigation.point_at(route, maxf(0.0, enemy.distance - 0.001))
	var direction: Vector2 = enemy.position - before
	# A spawn already inside a blocker's tile has no incoming side yet.
	if direction.length_squared() < 0.00000001: return enemy.position
	direction = direction.normalized()
	var offset: Vector2 = enemy.position - blocker.position
	var back := INF
	if absf(direction.x) > 0.000001:
		back = minf(back, (offset.x + 0.5 * signf(direction.x)) / direction.x)
	if absf(direction.y) > 0.000001:
		back = minf(back, (offset.y + 0.5 * signf(direction.y)) / direction.y)
	return enemy.position - direction * (maxf(0.0, back) + 0.00001)

static func damage(power: float, target: Dictionary, kind: String) -> float:
	if kind == "physical":
		var defense: float = target.defense
		if target.get("skill_left", 0.0) > 0: defense *= target.get("skill", {}).get("defense_multiplier", 1.0)
		return maxf(power - defense, power * 0.05)
	if kind == "arts": return power * (1.0 - clampf(target.resistance, 0, 95) / 100.0)
	return power

static func recover(unit: Dictionary, kind: String, amount: float) -> void:
	if unit.skill.enabled and unit.skill_left <= 0 and unit.skill.recovery == kind:
		unit.sp = minf(unit.skill.required, unit.sp + amount)

static func update_timers(b) -> void:
	for actor in b._state.units + b._state.enemies: actor.cooldown = maxf(0.0, actor.cooldown - b.STEP)
	for unit in b._state.units:
		unit["damage_reduction_left"] = maxf(0.0, unit.get("damage_reduction_left", 0.0) - b.STEP)
		if unit.skill_left > 0:
			unit.skill_left = maxf(0.0, unit.skill_left - b.STEP)
			if unit.skill_left <= 0: b.emit("skill_end", {"source": unit.id})
		else:
			recover(unit, "auto", b.STEP)
			if unit.skill.enabled and unit.skill.trigger == "automatic" and unit.sp + 0.000001 >= unit.skill.required: b._start_skill(unit)

static func unit_target(b, unit: Dictionary) -> Dictionary:
	var best: Dictionary = {}
	var best_remaining = INF
	for target in (b._state.units if unit.role == "healer" else b._state.enemies):
		if target.hp <= 0: continue
		var target_position: Vector2 = target.position
		var own_blocked := false
		if unit.role != "healer" and target.blocked_by != -1:
			own_blocked = target.blocked_by == unit.id
			var blocker: Dictionary = b._unit(target.blocked_by)
			if not blocker.is_empty(): target_position = blocked_target_position(b, target, blocker)
		if not own_blocked and not in_range(unit, target_position): continue
		if unit.role == "healer":
			if target.hp >= target.max_hp: continue
			var ratio: float = target.hp / target.max_hp
			if best.is_empty() or ratio < best_remaining - 0.000001 or (is_equal_approx(ratio, best_remaining) and target.id < best.id):
				best = target
				best_remaining = ratio
		else:
			if target.flying and not unit.anti_air: continue
			var remaining = Navigation.length_of(b._config.routes[target.route]) - target.distance
			if remaining <= 0: continue
			var preferred: bool = unit.role == "melee" and target.blocked_by == unit.id
			var old_preferred: bool = not best.is_empty() and unit.role == "melee" and best.blocked_by == unit.id
			if best.is_empty() or (preferred and not old_preferred) or (preferred == old_preferred and (remaining < best_remaining - 0.000001 or (is_equal_approx(remaining, best_remaining) and target.id < best.id))):
				best = target
				best_remaining = remaining
	return best

static func enemy_target(b, enemy: Dictionary) -> Dictionary:
	if enemy.blocked_by != -1:
		var blocker = b._unit(enemy.blocked_by)
		if not blocker.is_empty() and blocker.hp > 0: return blocker
	if not enemy.ranged: return {}
	var best: Dictionary = {}
	for unit in b._state.units:
		if unit.hp <= 0 or enemy.position.distance_to(unit.position) > enemy.range + 0.000001: continue
		if best.is_empty() or unit.order > best.order: best = unit
	return best

static func enemy_actions(b) -> void:
	for enemy in b._state.enemies:
		if enemy.hp <= 0: continue
		if not enemy.action.is_empty(): progress(b, enemy, false)
		elif enemy.cooldown <= 0.000001:
			var target = enemy_target(b, enemy)
			if not target.is_empty(): begin(b, enemy, target, false)

static func unit_actions(b) -> void:
	for unit in b._state.units:
		if unit.hp <= 0: continue
		if not unit.action.is_empty(): progress(b, unit, true)
		elif unit.cooldown <= 0.000001:
			var target = unit_target(b, unit)
			if not target.is_empty(): begin(b, unit, target, true)

static func begin(b, actor: Dictionary, target: Dictionary, friendly: bool) -> void:
	actor.target = target.id
	actor.cooldown = actor.interval
	if friendly and actor.skill_left > 0:
		actor.cooldown = maxf(actor.windup, actor.interval * actor.skill.get("interval_multiplier", 1.0))
	actor.action = {"target": target.id, "left": actor.windup}
	b.emit("attack_start", {"source": actor.id, "target": target.id, "from": actor.position,
		"to": target.position, "friendly": friendly})
	if actor.windup <= 0: progress(b, actor, friendly)

static func progress(b, actor: Dictionary, friendly: bool) -> void:
	actor.action.left -= b.STEP
	if actor.action.left > 0.000001: return
	var healing: bool = friendly and actor.role == "healer"
	var action: Dictionary = actor.action
	var target: Dictionary
	if not friendly or healing: target = b._unit(actor.action.target)
	else: target = b._enemy(actor.action.target)
	actor.action = {}
	actor.target = -1
	if target.is_empty() or target.hp <= 0:
		b.emit("miss", {"source": actor.id})
		return
	var power: float = action.get("power", actor.attack)
	var enhanced: bool = action.get("enhanced", false)
	var repeat_hit: bool = action.get("repeat_hit", false)
	if friendly and not repeat_hit:
		if actor.skill_left > 0: power *= actor.skill.multiplier
		if not healing:
			actor.attack_count += 1
			enhanced = actor.passive and actor.attack_count % 4 == 0
			if enhanced: power *= actor.passive_multiplier
		recover(actor, "attack", 1.0)
	var amount: float
	if healing:
		amount = minf(power, target.max_hp - target.hp)
		target.hp += amount
		if actor.skill_left > 0 and actor.skill.heal_damage_reduction > 0:
			target["damage_reduction"] = actor.skill.heal_damage_reduction
			target["damage_reduction_left"] = actor.skill.heal_buff_duration
	else:
		amount = damage(power, target, actor.damage_type)
		if not friendly and target.get("damage_reduction_left", 0.0) > 0: amount *= 1.0 - target.damage_reduction
		target.hp = maxf(0.0, target.hp - amount)
		if not friendly: recover(target, "hit", 1.0)
	b.emit("heal" if healing else "damage", {"source": actor.id, "target": target.id,
		"amount": amount, "damage_type": actor.damage_type, "enhanced": enhanced,
		"friendly": friendly, "from": actor.position, "to": target.position,
		"attack_count": actor.get("attack_count", 0)})
	var remaining: int = action.get("remaining_hits", 0) if repeat_hit else (actor.skill.hit_count - 1 if friendly and not healing and actor.skill_left > 0 else 0)
	if remaining > 0 and target.hp > 0:
		# A follow-up launches at the first impact and lands after its own flight.
		var flight: float = maxf(0.15, actor.windup)
		actor.target = target.id
		actor.action = {"target": target.id, "left": flight, "repeat_hit": true,
			"remaining_hits": remaining - 1, "power": power, "enhanced": enhanced}
		b.emit("attack_start", {"source": actor.id, "target": target.id, "from": actor.position,
			"to": target.position, "friendly": true, "windup": flight})
