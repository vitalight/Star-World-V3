extends RefCounted
## Trusted developer configuration. Runtime commands validate user input separately.
static func normalize(input: Dictionary) -> Dictionary:
	var c = input.duplicate(true)
	var defaults = {"life": 3, "initial_cost": 30.0, "cost_cap": 99.0, "cost_regen": 1.0, "deploy_limit": 8}
	for key in defaults:
		if not c.has(key): c[key] = defaults[key]
	assert(c.life > 0 and c.cost_cap >= c.initial_cost and c.initial_cost >= 0)
	assert(c.cost_regen >= 0 and c.deploy_limit > 0)
	for key in c.routes:
		assert(c.routes[key].size() >= 2)
		for i in range(1, c.routes[key].size()): assert(c.routes[key][i - 1].distance_to(c.routes[key][i]) > 0)
	for key in c.roster:
		var u = actor(c.roster[key])
		var role: String = u.get("role", "melee")
		var d = {"role": role, "terrain": "ground" if role == "melee" else "high", "cost": 10.0, "redeploy_time": 5.0,
			"block": 1 if role == "melee" else 0, "anti_air": false, "range": [Vector2i.ZERO, Vector2i.RIGHT],
			"passive": false, "passive_multiplier": 2.0, "name": key}
		for field in d:
			if not u.has(field): u[field] = d[field]
		assert(role in ["melee", "ranged", "healer"])
		assert(u.terrain == ("ground" if role == "melee" else "high"))
		assert(u.cost >= 0 and u.redeploy_time >= 0 and u.block >= 0)
		var skill = {"enabled": false, "recovery": "auto", "required": 5.0,
			"initial_sp": 0.0, "duration": 3.0, "multiplier": 2.0}
		skill.merge(u.get("skill", {}), true)
		assert(skill.required > 0 and skill.duration > 0)
		assert(skill.recovery in ["auto", "attack", "hit"])
		skill.initial_sp = clampf(skill.initial_sp, 0, skill.required)
		u.skill = skill
		c.roster[key] = u
	for key in c.enemies:
		var e = actor(c.enemies[key])
		var d = {"speed": 1.0, "ranged": false, "range": 3.0, "flying": false, "leak_damage": 1}
		for field in d:
			if not e.has(field): e[field] = d[field]
		assert(e.speed >= 0)
		c.enemies[key] = e
	for wave in c.waves:
		assert(c.enemies.has(wave.enemy) and c.routes.has(wave.route))
		assert(wave.count > 0 and wave.interval > 0 and wave.time >= 0)
	return c

static func actor(input: Dictionary) -> Dictionary:
	var a = {"max_hp": 200.0, "attack": 20.0, "defense": 0.0, "resistance": 0.0,
		"damage_type": "physical", "interval": 1.0, "windup": 0.2}
	a.merge(input, true)
	assert(a.max_hp > 0 and a.attack >= 0 and a.interval > 0)
	assert(a.windup >= 0 and a.windup <= a.interval)
	assert(a.damage_type in ["physical", "arts", "true"])
	return a
