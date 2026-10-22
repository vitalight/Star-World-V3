extends SceneTree
## Public-contract regression tests. Fixtures have no devtools/content dependency.
const Battle = preload("res://features/battle/battle.gd")
var checks = 0
var failures = 0

func _initialize() -> void:
	deployment()
	clocks_and_isolation()
	damage_and_actions()
	blocking()
	ranged()
	targeting()
	healing()
	skills()
	skill_modifiers()
	boundary_contracts()
	waves_and_determinism()
	print("Battle rules: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

func fixture() -> Dictionary:
	var terrain = {}
	for x in range(21):
		terrain[Vector2i(x, 0)] = "ground"
		terrain[Vector2i(x, 1)] = "high"
		terrain[Vector2i(x, -1)] = "high"
	return {"terrain": terrain, "routes": {"r": [Vector2.ZERO, Vector2(20, 0)]},
		"life": 3, "initial_cost": 50.0, "cost_regen": 0.0, "deploy_limit": 3,
		"roster": {"g": {"max_hp": 1000.0, "attack": 10.0, "block": 2, "interval": 0.5, "windup": 0.1},
			"s": {"role": "ranged", "terrain": "high", "block": 0, "anti_air": true, "attack": 10.0,
				"range": [Vector2i(0, -1), Vector2i(1, -1), Vector2i(2, -1)], "windup": 0.1},
			"h": {"role": "healer", "terrain": "high", "block": 0, "attack": 100.0, "range": [Vector2i(0, 1), Vector2i(1, 1)], "windup": 0.1}},
		"enemies": {"e": {"max_hp": 10000.0, "speed": 0.0, "attack": 0.0, "windup": 0.1}},
		"waves": [{"time": 0.0, "count": 1, "interval": 0.1, "enemy": "e", "route": "r"}]}

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(label)

func near(actual: float, expected: float, label: String) -> void:
	check(absf(actual - expected) < 0.0001, "%s (actual %.5f expected %.5f)" % [label, actual, expected])

func events(b, type: String, friendly = null) -> Array:
	return b.take_events().filter(func(e): return e.type == type and (friendly == null or e.get("friendly") == friendly))

func unit_id(b, roster: String) -> int:
	for u in b.snapshot().units:
		if u.roster_id == roster: return u.id
	return -1

func deployment() -> void:
	var c = fixture()
	var b = Battle.new(c)
	var original: Dictionary = b.snapshot()
	check(b.deployment_check("g",Vector2i.ZERO).ok and b.snapshot() == original and b.take_events().is_empty(), "Deployment preview is read-only and emits no events")
	for command in [["missing", Vector2i.ZERO, 0, "unknown_unit"], ["g", Vector2i(0, 1), 0, "wrong_terrain"], ["s", Vector2i.ZERO, 0, "wrong_terrain"], ["h", Vector2i.ZERO, 0, "wrong_terrain"], ["g", Vector2i(99, 0), 0, "wrong_terrain"], ["g", Vector2i.ZERO, 4, "invalid_facing"]]:
		var result = b.deploy(command[0], command[1], command[2])
		check(not result.ok and result.reason == command[3], "deployment rejects " + command[3])
	near(b.snapshot().cost, 50, "failed deployment never charges")
	var deployed = b.deploy("g", Vector2i.ZERO)
	check(deployed.ok, "valid ground deployment")
	check(b.deploy("g", Vector2i(1, 0)).reason == "already_deployed", "one instance per roster entry")
	c.roster.other = c.roster.g.duplicate(true)
	var other = Battle.new(c)
	other.deploy("g", Vector2i.ZERO)
	check(other.deploy("other", Vector2i.ZERO).reason == "occupied", "occupied tile rejected")
	c.deploy_limit = 1
	other = Battle.new(c)
	other.deploy("g", Vector2i.ZERO)
	check(other.deploy("s", Vector2i(0, 1)).reason == "deploy_limit", "deployment cap rejected")
	c.initial_cost = 0.0
	other = Battle.new(c)
	check(other.deploy("g", Vector2i.ZERO).reason == "insufficient_cost", "insufficient cost rejected")
	near(other.snapshot().cost, 0, "insufficient cost preserves balance")
	check(b.retreat(deployed.id).ok and b.snapshot().units.is_empty(), "retreat removes deployed unit")
	near(b.snapshot().cost, 45, "retreat refunds half")
	check(b.deploy("g", Vector2i.ZERO).reason == "redeploy_cooldown", "retreat starts redeploy cooldown")
	b.start()
	b.advance(5.0)
	check(b.deploy("g", Vector2i.ZERO).ok, "redeploy succeeds after cooldown")
	check(b.snapshot().units[0].attack_count == 0 and b.snapshot().units[0].id != deployed.id, "redeploy creates fresh identity and counters")
	check(b.snapshot().units[0].hp == 1000, "redeploy restores full hp")
	check(not b.retreat(-1).ok and not b.activate_skill(-1).ok, "missing command target rejected")
	c = fixture()
	c.roster.g.cost = 11.0
	c.cost_cap = 50.0
	b = Battle.new(c)
	deployed = b.deploy("g", Vector2i.ZERO)
	b.retreat(deployed.id)
	near(b.snapshot().cost, 44.0, "odd deployment refund rounds down")

func clocks_and_isolation() -> void:
	var c = fixture()
	c.cost_regen = 2.0
	c.cost_cap = 51.0
	c.roster.g.skill = {"enabled": true}
	var b = Battle.new(c)
	b.deploy("g", Vector2i.ZERO)
	var copy = b.snapshot()
	copy.units.clear()
	check(b.snapshot().units.size() == 1, "snapshot is isolated")
	copy = b.configuration()
	copy.roster.clear()
	check(b.configuration().roster.size() == 3, "configuration is isolated")
	copy = b.find_unit(unit_id(b, "g"))
	copy.hp = 0
	check(b.snapshot().units[0].hp == 1000, "unit lookup is isolated")
	check(b.start() and not b.start(), "start only accepted once")
	b.advance(-1)
	near(b.snapshot().time, 0, "negative delta ignored")
	b.set_paused(true)
	var frozen = b.snapshot()
	b.advance(5)
	check(b.snapshot() == frozen, "pause freezes every simulation clock")
	b.step()
	near(b.snapshot().time, Battle.STEP, "paused single-step advances exactly one tick")
	b.set_paused(false)
	b.step()
	near(b.snapshot().time, Battle.STEP, "single step ignored while running")
	b.advance(20)
	near(b.snapshot().cost, 51.0, "cost regeneration respects cap")
	check(b.snapshot().units[0].sp <= 5, "SP respects cap")
	b.take_events()
	check(b.take_events().is_empty(), "events are consumed once")
	b.reset()
	check(b.snapshot().phase == "ready" and b.snapshot().time == 0 and b.snapshot().units.is_empty() and b.take_events().is_empty(), "reset clears clocks, roster instances and events")
	near(b.snapshot().cost, 50, "reset restores initial cost")

func damage_and_actions() -> void:
	for item in [["physical", 80.0, 60.0, 20.0], ["physical", 200.0, 0.0, 5.0], ["arts", 999.0, 60.0, 40.0], ["arts", 0.0, 200.0, 5.0], ["arts", 0.0, -20.0, 100.0], ["true", 999.0, 99.0, 100.0]]:
		var c = fixture()
		c.roster.g.attack = 100.0
		c.roster.g.damage_type = item[0]
		c.enemies.e.defense = item[1]
		c.enemies.e.resistance = item[2]
		var b = Battle.new(c)
		b.deploy("g", Vector2i.ZERO)
		b.start()
		b.advance(0.05)
		near(b.snapshot().enemies[0].hp, 10000, "windup delays damage")
		b.advance(0.1)
		near(10000 - b.snapshot().enemies[0].hp, item[3], "damage formula " + item[0])
		b.advance(0.2)
		near(10000 - b.snapshot().enemies[0].hp, item[3], "cooldown prevents extra hit")
	var c = fixture()
	c.enemies.e.max_hp = 5.0
	var b = Battle.new(c)
	b.deploy("g", Vector2i.ZERO)
	b.start()
	b.advance(1)
	check(b.snapshot().killed == 1 and b.snapshot().phase == "victory", "lethal damage removes enemy and wins")
	var frozen = b.snapshot()
	b.advance(999)
	check(b.snapshot() == frozen and b.deploy("s", Vector2i(0, 1)).reason == "finished", "terminal battle frozen and commands rejected")
	c = fixture()
	c.roster.g.max_hp = 5.0
	c.enemies.e.attack = 100.0
	b = Battle.new(c)
	b.deploy("g", Vector2i.ZERO)
	b.start()
	b.advance(0.3)
	check(b.snapshot().units.is_empty() and b.snapshot().redeploy.g > 0, "unit death removes occupancy and starts redeploy")
	near(b.snapshot().cost, 40, "death does not refund cost")
	check(b.snapshot().enemies[0].blocked_by == -1, "death releases block")

func blocking() -> void:
	var c = fixture()
	c.enemies.e.speed = 1.0
	c.waves[0].count = 3
	var b = Battle.new(c)
	var id: int = b.deploy("g", Vector2i(1, 0)).id
	b.start()
	b.advance(2.0)
	var state = b.snapshot()
	check(state.units[0].blocked.size() == 2, "block capacity filled")
	check(state.enemies[0].blocked_by == id and state.enemies[1].blocked_by == id and state.enemies[2].blocked_by == -1, "arrival order assigns first two enemies")
	check(state.enemies[2].distance > state.enemies[0].distance, "excess enemy passes blocker")
	var distance: float = state.enemies[0].distance
	b.advance(0.5)
	near(b.snapshot().enemies[0].distance, distance, "blocked enemy stays still during cooldown")
	b.retreat(id)
	check(b.snapshot().enemies.all(func(e): return e.blocked_by == -1), "retreat releases all blocks immediately")
	b.advance(0.2)
	check(b.snapshot().enemies[0].distance > distance, "released enemy resumes moving")
	c = fixture()
	c.enemies.e.speed = 600.0
	b = Battle.new(c)
	b.deploy("g", Vector2i(2, 0))
	b.start()
	b.advance(Battle.STEP)
	check(b.snapshot().enemies[0].blocked_by != -1, "high speed cannot tunnel through occupied tile")
	c.enemies.e.flying = true
	b = Battle.new(c)
	b.deploy("g", Vector2i(2, 0))
	b.start()
	b.advance(Battle.STEP)
	check(b.snapshot().enemies[0].blocked_by == -1, "flying enemy ignores blocking")
	b.advance(0.1)
	check(events(b, "damage", true).is_empty(), "melee without anti-air cannot hit flying enemy")

func ranged() -> void:
	var c = fixture()
	c.enemies.e.ranged = true
	c.enemies.e.attack = 15.0
	c.enemies.e.speed = 1.0
	c.enemies.e.windup = 0.3
	c.roster.h.role = "ranged"
	c.roster.s.attack = 0.0
	c.roster.h.attack = 0.0
	var b = Battle.new(c)
	var first: int = b.deploy("s", Vector2i(0, 1)).id
	var last: int = b.deploy("h", Vector2i(0, -1)).id
	b.start()
	b.advance(Battle.STEP)
	check(b.snapshot().enemies[0].target == last, "ranged enemy prioritizes latest deployed in range")
	near(b.snapshot().enemies[0].distance, 0, "attack start stops movement")
	b.advance(0.1)
	near(b.snapshot().enemies[0].distance, 0, "windup holds enemy position")
	b.retreat(last)
	b.advance(0.3)
	check(events(b, "miss").size() == 1, "withdrawn locked target causes miss")
	near(b.find_unit(first).hp, 200, "miss does not retarget first deployed unit")
	check(b.snapshot().enemies[0].distance > 0, "cooldown resumes movement")
	b.advance(0.7)
	check(b.snapshot().enemies[0].target == first, "next attack acquires remaining target")
	c = fixture()
	c.enemies.e.ranged = true
	c.enemies.e.attack = 10.0
	c.enemies.e.range = 0.05
	c.enemies.e.windup = 0.0
	c.roster.g.attack = 0.0
	b = Battle.new(c)
	first = b.deploy("g", Vector2i.ZERO).id
	b.deploy("s", Vector2i(0, 1))
	b.start()
	b.advance(0.1)
	check(b.find_unit(first).hp < 1000, "blocked ranged enemy attacks blocker regardless of latest deployment and range")

func targeting() -> void:
	var c = fixture()
	c.enemies.e.flying = true
	var b = Battle.new(c)
	b.deploy("s", Vector2i(0, 1))
	b.start()
	b.advance(0.2)
	near(10000 - b.snapshot().enemies[0].hp, 10, "anti-air ranged attack hits flying enemy")
	for facing in range(4):
		c = fixture()
		c.roster.g.range = [Vector2i.RIGHT]
		c.roster.g.block = 0
		var offset = Vector2.RIGHT.rotated(facing * PI / 2).round()
		c.routes.r = [offset, offset + Vector2(10, 10)]
		b = Battle.new(c)
		b.deploy("g", Vector2i.ZERO, facing)
		b.start()
		b.advance(0.2)
		near(10000 - b.snapshot().enemies[0].hp, 10, "directional template rotation %d" % facing)
	c = fixture()
	c.roster.g.range = [Vector2i.RIGHT]
	c.roster.g.block = 0
	c.routes.r = [Vector2(1.5, 0), Vector2(20, 0)]
	b = Battle.new(c)
	b.deploy("g", Vector2i.ZERO)
	b.start()
	b.advance(0.2)
	near(10000 - b.snapshot().enemies[0].hp, 10, "range boundary included")
	c.routes.r = [Vector2(1.51, 0), Vector2(20, 0)]
	b = Battle.new(c)
	b.deploy("g", Vector2i.ZERO)
	b.start()
	b.advance(0.2)
	near(b.snapshot().enemies[0].hp, 10000, "outside range excluded")
	c = fixture()
	c.roster.g.range = [Vector2i.ZERO, Vector2i.RIGHT]
	c.roster.g.block = 0
	c.routes.long = [Vector2(1, 0), Vector2(100, 0)]
	c.waves.append({"time": 0.0, "count": 1, "interval": 1.0, "enemy": "e", "route": "long"})
	b = Battle.new(c)
	b.deploy("g", Vector2i.ZERO)
	b.start()
	b.advance(Battle.STEP)
	var target: int = b.snapshot().units[0].target
	check(b.find_enemy(target).route == "r", "targeting compares remaining route length instead of distance traveled")
	c = fixture()
	c.waves[0].count = 2
	c.waves[0].interval = 0.01
	b = Battle.new(c)
	b.deploy("g", Vector2i.ZERO)
	b.start()
	b.advance(Battle.STEP)
	check(b.snapshot().units[0].target == b.snapshot().enemies[0].id, "equal priority breaks by stable ID")

func healing() -> void:
	var c = fixture()
	c.enemies.e.ranged = true
	c.enemies.e.attack = 30.0
	c.enemies.e.windup = 0.0
	c.enemies.e.interval = 0.5
	c.roster.g.defense = 10.0
	c.roster.g.resistance = 95.0
	var b = Battle.new(c)
	var healer: int = b.deploy("h", Vector2i(0, -1)).id
	var guard: int = b.deploy("g", Vector2i.ZERO).id
	b.start()
	b.advance(0.25)
	var heals = events(b, "heal")
	check(heals.size() == 1 and heals[0].target == guard, "healer selects damaged friendly")
	if not heals.is_empty(): near(heals[0].amount, 20.0, "healing caps at missing hp and ignores defense")
	near(b.find_unit(guard).hp, 1000, "healing cannot overflow")
	b.advance(0.2)
	check(events(b, "damage", true).all(func(e): return e.source != healer), "healer never attacks enemies")
	c = fixture()
	b = Battle.new(c)
	b.deploy("h", Vector2i(0, -1))
	b.start()
	b.advance(1)
	check(events(b, "heal").is_empty(), "full health targets do not trigger healing")
	c = fixture()
	c.roster.g.max_hp = 10.0
	c.enemies.e.attack = 100.0
	c.enemies.e.windup = 0.0
	b = Battle.new(c)
	guard = b.deploy("g", Vector2i.ZERO).id
	b.deploy("h", Vector2i(0, -1))
	b.start()
	b.advance(1)
	check(b.find_unit(guard).is_empty() and events(b, "heal").is_empty(), "dead friendly cannot be healed or resurrected")

func skills() -> void:
	var c = fixture()
	c.roster.g.passive = true
	c.roster.g.interval = 0.25
	c.roster.g.windup = 0.0
	var b = Battle.new(c)
	var id: int = b.deploy("g", Vector2i.ZERO).id
	b.start()
	b.advance(3.0)
	var hits = events(b, "damage", true)
	check(hits.size() == 12, "12 attacks occur at configured intervals")
	for i in range(hits.size()):
		check(hits[i].enhanced == ((i + 1) % 4 == 0), "passive enhanced attack %d" % (i + 1))
		near(hits[i].amount, 20.0 if (i + 1) % 4 == 0 else 10.0, "passive damage %d" % (i + 1))
	b.retreat(id)
	b.advance(5.0)
	b.deploy("g", Vector2i.ZERO)
	check(b.snapshot().units[0].attack_count == 0, "retreat clears passive count on redeploy")
	c = fixture()
	c.roster.g.passive = true
	c.routes.r = [Vector2(10, 0), Vector2(20, 0)]
	b = Battle.new(c)
	b.deploy("g", Vector2i.ZERO)
	b.start()
	b.advance(5)
	check(b.snapshot().units[0].attack_count == 0, "no target does not accumulate passive attacks")
	for recovery in ["auto", "attack", "hit"]:
		c = fixture()
		c.roster.g.skill = {"enabled": true, "recovery": recovery, "required": 2.0, "duration": 1.0}
		c.enemies.e.interval = 0.5
		c.enemies.e.attack = 1.0
		b = Battle.new(c)
		id = b.deploy("g", Vector2i.ZERO).id
		check(b.activate_skill(id).reason == "not_running", "skill requires battle start")
		b.start()
		check(b.activate_skill(id).reason == "insufficient_sp", recovery + " insufficient SP rejected")
		b.advance(2.1)
		near(b.find_unit(id).sp, 2, recovery + " recovery reaches cap")
		check(b.activate_skill(id).ok, recovery + " full SP activates")
		check(b.activate_skill(id).reason == "skill_active", recovery + " active skill cannot stack")
		b.take_events()
		b.advance(0.6)
		near(b.find_unit(id).sp, 0, recovery + " active skill blocks SP recovery")
		var enhanced_hits = events(b, "damage", true)
		check(not enhanced_hits.is_empty() and enhanced_hits.all(func(e): return e.amount == 20), recovery + " active skill increases damage")
		b.advance(0.5)
		check(b.find_unit(id).skill_left == 0, recovery + " skill expires")
		b.take_events()
		b.advance(0.5)
		check(events(b, "damage", true).all(func(e): return e.amount == 10), recovery + " base damage restored")

func boundary_contracts() -> void:
	# Heal by health ratio, rather than absolute missing HP or deployment order.
	for tie in [false, true]:
		var c = fixture()
		c.roster.g.attack = 0.0
		c.roster.g.block = 0
		c.roster.other = c.roster.g.duplicate(true)
		c.roster.other.max_hp = 1000.0 if tie else 100.0
		c.routes.second = [Vector2(1, 0), Vector2(20, 0)]
		c.enemies.e.merge({"ranged": true, "range": 0.1, "attack": 30.0, "windup": 0.0, "interval": 10.0}, true)
		c.waves.append({"time": 0.0, "count": 1, "interval": 1.0, "enemy": "e", "route": "second"})
		var b = Battle.new(c)
		var first: int = b.deploy("g", Vector2i.ZERO).id
		var second: int = b.deploy("other", Vector2i(1, 0)).id
		b.deploy("h", Vector2i(0, -1))
		b.start()
		b.advance(0.2)
		var heals = events(b, "heal")
		check(heals.size() == 1 and heals[0].target == (first if tie else second), "healing breaks equal ratios by ID" if tie else "healing prioritizes lowest health ratio")
	var c = fixture()
	c.roster.g.block = 0
	c.roster.g.windup = 0.3
	c.roster.g.range = [Vector2i.RIGHT]
	c.enemies.e.speed = 2.0
	c.routes.r = [Vector2(1, 0), Vector2(20, 0)]
	var b = Battle.new(c)
	b.deploy("g", Vector2i.ZERO)
	b.start()
	b.advance(0.4)
	check(b.snapshot().enemies[0].position.x > 1.5 and events(b, "damage", true).size() == 1, "locked attack hits even after target leaves range")
	c = fixture()
	c.enemies.e.max_hp = 50.0
	c.roster.g.windup = 0.3
	c.roster.s.attack = 100.0
	c.roster.s.windup = 0.0
	c.waves.append({"time": 3.0, "count": 1, "interval": 1.0, "enemy": "e", "route": "r"})
	b = Battle.new(c)
	var guard: int = b.deploy("g", Vector2i.ZERO).id
	b.deploy("s", Vector2i(0, 1))
	b.start()
	b.advance(0.5)
	check(events(b, "miss").size() == 1 and b.find_unit(guard).attack_count == 0, "dead locked target causes miss without passive count")
	c = fixture()
	c.enemies.e.max_hp = 10.0
	c.roster.g.passive = true
	c.roster.g.windup = 0.0
	c.roster.g.interval = 0.1
	c.waves[0].count = 4
	c.waves[0].interval = 0.3
	b = Battle.new(c)
	b.deploy("g", Vector2i.ZERO)
	b.start()
	b.advance(2.0)
	var hits = events(b, "damage", true)
	check(hits.size() == 4 and hits[3].attack_count == 4 and hits[3].enhanced, "passive count survives target changes and targetless gaps")
	c = fixture()
	c.routes.urgent = [Vector2(1, 0), Vector2(2, 0)]
	c.waves.append({"time": 0.0, "count": 1, "interval": 1.0, "enemy": "e", "route": "urgent"})
	b = Battle.new(c)
	b.deploy("g", Vector2i.ZERO)
	b.start()
	b.advance(Battle.STEP)
	check(b.find_enemy(b.snapshot().units[0].target).route == "r", "melee prioritizes own blocked enemy over closer-to-exit enemy")
	# A new deployment does not change an action already in progress.
	c = fixture()
	c.enemies.e.merge({"ranged": true, "attack": 10.0, "windup": 0.3}, true)
	c.roster.s.attack = 0.0
	c.roster.h.attack = 0.0
	b = Battle.new(c)
	var first: int = b.deploy("s", Vector2i(0, 1)).id
	b.start()
	b.advance(0.1)
	var last: int = b.deploy("h", Vector2i(0, -1)).id
	b.advance(0.3)
	var damage_events = events(b, "damage", false)
	check(damage_events.size() == 1 and damage_events[0].target == first, "new deployment does not steal an already locked attack")
	b.advance(0.7)
	check(b.snapshot().enemies[0].target == last, "next action chooses new latest deployment")

func waves_and_determinism() -> void:
	var c = fixture()
	c.enemies.e.speed = 10.0
	c.routes.r = [Vector2.ZERO, Vector2(1, 0), Vector2(1, 1)]
	c.waves.append({"time": 2.0, "count": 1, "interval": 1.0, "enemy": "e", "route": "r"})
	var b = Battle.new(c)
	b.start()
	b.advance(0.15)
	check(b.snapshot().enemies[0].position.distance_to(Vector2(1, 0.5)) < 0.001, "movement follows corners")
	b.advance(0.5)
	check(b.snapshot().phase == "running" and b.snapshot().remaining == 1, "pending wave prevents early victory")
	b.advance(2)
	check(b.snapshot().phase == "victory" and b.snapshot().life == 1 and b.snapshot().escaped == 2, "surviving leakage wins only after all waves")
	c.life = 1
	b = Battle.new(c)
	b.start()
	b.advance(5)
	check(b.snapshot().phase == "defeat" and b.snapshot().spawned == 1, "life depletion stops later waves immediately")
	c = fixture()
	c.enemies.e.speed = 1.0
	c.enemies.e.ranged = true
	c.cost_regen = 1.0
	var small = Battle.new(c)
	var large = Battle.new(c)
	for battle in [small, large]:
		battle.deploy("s", Vector2i(0, 1))
		battle.start()
	for i in range(180): small.advance(Battle.STEP)
	large.advance(3)
	check(small.snapshot() == large.snapshot(), "fixed steps independent of time partition")
	check(small.take_events() == large.take_events(), "event sequence independent of time partition")
	var expected = large.snapshot()
	large.reset()
	large.deploy("s", Vector2i(0, 1))
	large.start()
	large.advance(3)
	check(large.snapshot() == expected, "reset replay deterministic")

func skill_modifiers() -> void:
	# Defense applies only while the skill is active and retains physical minimum damage.
	for kind in ["physical", "arts", "true"]:
		var c = fixture()
		c.roster.g.attack = 0.0
		c.roster.g.defense = 10.0
		c.roster.g.skill = {"enabled":true,"initial_sp":1.0,"required":1.0,"duration":0.3,"multiplier":1.0,"defense_multiplier":2.5}
		c.enemies.e.attack = 50.0
		c.enemies.e.damage_type = kind
		c.enemies.e.interval = 0.5
		var b = Battle.new(c)
		var id: int = b.deploy("g",Vector2i.ZERO).id
		b.start(); b.activate_skill(id); b.advance(0.2)
		near(1000.0 - b.find_unit(id).hp, 25.0 if kind == "physical" else 50.0, "Active defense modifier against " + kind)
		near(b.find_unit(id).defense,10.0,"Skill preserves base defense")
		b.advance(0.45)
		near(1000.0 - b.find_unit(id).hp, 65.0 if kind == "physical" else 100.0, "Defense returns to normal after expiry")
	var c = fixture()
	c.roster.g.skill = {"enabled":true,"initial_sp":1.0,"required":1.0,"duration":0.7,"multiplier":1.0,"interval_multiplier":0.5}
	c.roster.g.interval = 0.6
	var b = Battle.new(c)
	var id: int = b.deploy("g",Vector2i.ZERO).id
	b.start(); b.activate_skill(id); b.advance(1.6)
	var attacks: Array = events(b,"attack_start",true)
	check(attacks.size() == 5, "Rapid-fire skill increases actual attack count")
	if attacks.size() >= 5:
		near(attacks[1].time - attacks[0].time,0.3,"Active rapid-fire interval is halved")
		near(attacks[4].time - attacks[3].time,0.6,"Base attack interval resumes after expiry")
	near(b.find_unit(id).interval,0.6,"Rapid-fire preserves base interval")
