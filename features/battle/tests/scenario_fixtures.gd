extends RefCounted
## Pure battle regression fixtures; no scene, content or presentation dependencies.
static func long_range() -> Array:
	var cells: Array = []
	for x in range(5):
		for y in range(-1, 2): cells.append(Vector2i(x, y))
	return cells

static func base() -> Dictionary:
	var terrain = {}
	for x in range(12):
		for y in range(1, 6): terrain[Vector2i(x, y)] = "ground" if y in [3, 4] else "high"
	return {"size": Vector2i(12, 7), "terrain": terrain, "life": 3,
		"initial_cost": 50.0, "cost_cap": 99.0, "cost_regen": 1.0, "deploy_limit": 4,
		"routes": {"main": [Vector2(0, 3), Vector2(11, 3)]},
		"roster": {
			"guard": {"name": "近卫", "max_hp": 600.0, "attack": 45.0, "defense": 8.0, "block": 2, "interval": 0.75},
			"sniper": {"name": "射手", "role": "ranged", "terrain": "high", "block": 0, "anti_air": true, "range": long_range(), "attack": 50.0, "interval": 0.6},
			"medic": {"name": "医疗", "role": "healer", "terrain": "high", "block": 0, "range": long_range(), "attack": 45.0},
			"reserve": {"name": "重装", "max_hp": 900.0, "attack": 15.0, "block": 3, "defense": 15.0}},
		"enemies": {
			"soldier": {"max_hp": 180.0, "speed": 1.2, "attack": 18.0},
			"rifle": {"max_hp": 240.0, "speed": 0.8, "attack": 25.0, "ranged": true, "range": 4.0, "windup": 0.35},
			"drone": {"max_hp": 120.0, "speed": 1.4, "attack": 0.0, "flying": true}},
		"waves": [{"time": 1.0, "count": 3, "interval": 2.0, "enemy": "soldier", "route": "main"}]}

static func deploy(id: String, cell: Vector2i, facing: int = 2, time: float = 0.0, reason: String = "") -> Dictionary:
	return {"at": time, "op": "deploy", "roster": id, "cell": cell, "facing": facing, "reason": reason}

static func event_check(label: String, type: String, fields: Dictionary = {}, minimum: int = 1) -> Dictionary:
	return {"label": label, "kind": "event", "type": type, "fields": fields, "minimum": minimum}

static func state_check(label: String, field: String, value) -> Dictionary:
	return {"label": label, "kind": "state", "field": field, "value": value}

static func sample(name: String, rules: String, config: Dictionary, commands: Array, checks: Array, duration: float = 20.0) -> Dictionary:
	return {"name": name, "rules": rules, "config": config, "commands": commands, "checks": checks, "duration": duration}

static func catalog() -> Array:
	var groups: Array = []
	var c = base()
	c.deploy_limit = 1
	c.initial_cost = 10.0
	c.waves[0].time = 30.0
	groups.append({"name": "1 · 部署与战场管理", "cases": [sample("合法性、返费与再部署", "近战上地面，远程/医疗上高台；非法命令不扣费。撤退返还50%，5秒后可再部署。朝向：右/下/左/上。", c,
		[deploy("guard", Vector2i(2, 2), 2, 0, "wrong_terrain"),
		deploy("sniper", Vector2i(6, 3), 2, 0, "wrong_terrain"), deploy("medic", Vector2i(6, 3), 2, 0, "wrong_terrain"),
		deploy("guard", Vector2i(6, 3), 4, 0, "invalid_facing"), deploy("guard", Vector2i(6, 3)),
		deploy("guard", Vector2i(6, 3), 2, 0, "already_deployed"), deploy("reserve", Vector2i(6, 3), 2, 0, "occupied"),
		deploy("sniper", Vector2i(6, 2), 2, 0, "deploy_limit"),
		{"at": 1.0, "op": "retreat", "roster": "guard"}, deploy("sniper", Vector2i(6, 2), 2, 1.0, "insufficient_cost"),
		deploy("guard", Vector2i(6, 3), 2, 1.0, "redeploy_cooldown"),
		deploy("guard", Vector2i(6, 3), 2, 6.1)],
		[{"label": "所有预设命令结果与失败前后费用正确", "kind": "commands"}, event_check("两次合法部署", "deploy", {}, 2), event_check("撤退释放位置", "retreat")], 8.0)]})
	c = base()
	c.routes.main = [Vector2(1, 3), Vector2(11, 3)]
	c.waves = [{"time": 0.0, "count": 1, "interval": 1.0, "enemy": "rifle", "route": "main"}]
	c.enemies.rifle.max_hp = 9000.0
	c.roster.guard.attack = 0.0
	c.roster.sniper.attack = 0.0
	var crossfire = sample("最后部署优先与走停", "远程敌人仅出手期间停步；冷却时移动。优先范围内最新部署者；锁定后不因新部署换目标。", c,
		[deploy("guard", Vector2i(4, 3)), deploy("sniper", Vector2i(4, 2), 2, 1.0)],
		[event_check("敌方远程造成伤害", "damage", {"friendly": false}), {"label": "冷却移动、动作停步", "kind": "enemy_motion"}, {"label": "新攻击优先最后部署者", "kind": "latest_target"}], 9.0)
	c = base()
	c.waves = [{"time": 0.0, "count": 2, "interval": 1.0, "enemy": "drone", "route": "main"}]
	var air = sample("方向与对空", "飞行敌人穿过地面阻挡；射手可对空，近卫不能。射手向左覆盖路线，切换手动朝向可观察盲区。", c,
		[deploy("guard", Vector2i(6, 3)), deploy("sniper", Vector2i(6, 2))],
		[event_check("射手对空命中", "damage", {"friendly": true}), state_check("击落全部飞行敌人", "killed", 2), {"label": "飞行敌人从未被阻挡", "kind": "no_event", "type": "block"}], 14.0)
	groups.append({"name": "2 · 远程交火与对空", "cases": [crossfire, air]})
	c = base()
	c.roster.guard.attack = 0.0
	c.enemies.soldier.attack = 0.0
	c.waves[0].interval = 0.4
	var block = sample("阻挡2、溢出与撤退释放", "近卫阻挡2名地面敌人，第三名继续前进。被阻挡敌人攻击阻挡者；撤退立即释放。", c,
		[deploy("guard", Vector2i(4, 3)), {"at": 7.0, "op": "retreat", "roster": "guard"}],
		[{"label": "阻挡数量达到2但不超额", "kind": "block_capacity", "count": 2}, event_check("近战敌人反击", "damage", {"friendly": false}), event_check("撤退解除两份阻挡", "unblock", {}, 2), event_check("溢出敌人抵达终点", "escape")], 18.0)
	c = base()
	c.roster.guard.max_hp = 25.0
	c.roster.guard.attack = 0.0
	c.enemies.soldier.attack = 100.0
	c.waves[0].count = 1
	var death = sample("死亡释放与不返费", "干员死亡释放占位和阻挡，不返还费用，进入再部署冷却；敌人继续前进。", c,
		[deploy("guard", Vector2i(3, 3))], [event_check("干员死亡", "death", {"roster_id": "guard"}), event_check("死亡解除阻挡", "unblock"), event_check("敌人继续前进并漏过", "escape")], 15.0)
	groups.append({"name": "3 · 近战与阻挡", "cases": [block, death]})
	var damage_cases: Array = []
	for kind in ["physical", "arts", "true"]:
		c = stationary()
		c.roster.guard.attack = 100.0
		c.roster.guard.damage_type = kind
		c.enemies.soldier.defense = 80.0
		c.enemies.soldier.resistance = 60.0
		var expected: float = {"physical": 20.0, "arts": 40.0, "true": 100.0}[kind]
		damage_cases.append(sample("伤害 · " + kind, "攻击100、防御80、法抗60：物理20 / 法术40 / 真实100。物理最低5%，法抗限制0～95。", c,
			[deploy("guard", Vector2i(4, 3))], [event_check("实际伤害 = %.0f" % expected, "damage", {"friendly": true, "amount": expected})], 3.0))
	c = stationary()
	c.enemies.soldier.attack = 60.0
	c.roster.guard.attack = 0.0
	damage_cases.append(sample("治疗与生命上限", "医疗优先生命比例最低的范围内友军；不治疗满血，不攻击敌人，不复活。治疗忽略护甲法抗且不溢出。", c,
		[deploy("guard", Vector2i(4, 3)), deploy("medic", Vector2i(6, 2))],
		[event_check("友军受伤", "damage", {"friendly": false}), event_check("医疗恢复生命", "heal"), {"label": "所有生命均未超过上限", "kind": "hp_cap"}], 8.0))
	groups.append({"name": "4 · 伤害与治疗", "cases": damage_cases})
	c = stationary()
	c.roster.guard.passive = true
	c.roster.guard.interval = 0.6
	var skill_cases = [sample("三普攻后强化下一击", "第4、8、12次有效攻击为200%攻击力；换目标不清计数，无目标不计数。离场后清空。", c,
		[deploy("guard", Vector2i(4, 3))], [event_check("第4击强化", "damage", {"attack_count": 4, "enhanced": true}), event_check("第8击强化", "damage", {"attack_count": 8, "enhanced": true}), event_check("第12击强化", "damage", {"attack_count": 12, "enhanced": true})], 8.0)]
	for recovery in ["auto", "attack", "hit"]:
		c = stationary()
		c.enemies.soldier.attack = 9.0
		c.roster.guard.skill = {"enabled": true, "recovery": recovery, "required": 2.0, "duration": 2.0}
		skill_cases.append(sample("主动技能 · " + recovery, "技力方式：" + recovery + "。满2点手动释放，攻击力翻倍持续2秒；持续期不回复、不叠加，结束恢复。", c,
			[deploy("guard", Vector2i(4, 3)), {"at": 0.1, "op": "skill", "roster": "guard", "reason": "insufficient_sp"}, {"at": 3.0, "op": "skill", "roster": "guard"}, {"at": 3.1, "op": "skill", "roster": "guard", "reason": "skill_active"}],
			[{"label": "释放条件与不叠加", "kind": "commands"}, event_check("技能释放", "skill_start"), event_check("持续期结束", "skill_end"), event_check("技能期间伤害翻倍", "damage", {"friendly": true, "amount": 90.0})], 7.0))
	groups.append({"name": "5 · 被动与主动技能", "cases": skill_cases})
	c = base()
	c.routes.second = [Vector2(0, 4), Vector2(5, 4), Vector2(5, 3), Vector2(11, 3)]
	c.waves = [{"time": 0.0, "count": 1, "interval": 1.0, "enemy": "drone", "route": "main", "number": 1}, {"time": 12.0, "count": 1, "interval": 1.0, "enemy": "soldier", "route": "second", "number": 2}]
	var waves = sample("双路线、延迟波次与存活胜利", "首波漏怪后等待第二波；基地尚有生命时，全波处理完毕才胜利。终局冻结。", c, [],
		[state_check("等待后续波次期间仍在战斗", "phase_at_gap", "running"), state_check("处理两波后胜利", "phase", "victory"), state_check("两条路线各漏1名", "escaped", 2)], 25.0)
	c = base()
	var lose = sample("基地耗尽失败", "不部署，第三名敌人漏过时基地生命归零，立即失败。", c, [], [state_check("基地生命归零", "life", 0), state_check("战斗失败", "phase", "defeat")], 20.0)
	groups.append({"name": "6 · 路线、波次与胜负", "cases": [waves, lose]})
	c = base()
	c.roster.guard.passive = true
	c.roster.guard.skill = {"enabled": true, "required": 3.0, "duration": 3.0}
	c.waves = [{"time": 0.0, "count": 4, "interval": 1.0, "enemy": "soldier", "route": "main", "number": 1}, {"time": 4.0, "count": 2, "interval": 1.0, "enemy": "rifle", "route": "main", "number": 2}, {"time": 6.0, "count": 2, "interval": 1.0, "enemy": "drone", "route": "main", "number": 3}]
	var commands = [deploy("guard", Vector2i(6, 3)), deploy("sniper", Vector2i(6, 2)), deploy("medic", Vector2i(8, 2)), {"at": 5.0, "op": "skill", "roster": "guard"}]
	var combined = sample("综合防守 · 预设获胜", "预设依次部署近卫、射手、医疗，再开启技能。可手动重试，撤退近卫观察放行，移除射手观察飞行漏怪。", c, commands,
		[state_check("预设防守获胜", "phase", "victory"), event_check("阻挡生效", "block"), event_check("医疗参与防守", "heal"), event_check("技能成功释放", "skill_start"), state_check("全部8名敌人被消灭", "killed", 8)], 30.0)
	var no_air_config = c.duplicate(true)
	no_air_config.roster.guard.max_hp = 1800.0
	no_air_config.roster.guard.attack = 100.0
	var no_air = sample("综合变体 · 缺少对空", "只部署地面干员与医疗；地面敌人被阻挡，飞行敌人穿过防线。", no_air_config,
		[deploy("guard", Vector2i(6, 3)), deploy("medic", Vector2i(8, 2))], [event_check("飞行敌人漏过", "escape"), state_check("共漏过2架飞行敌人", "escaped", 2)], 35.0)
	var empty = sample("综合变体 · 空场失败", "同一综合关配置，不部署，验证失败路径。", c, [], [state_check("空场防守失败", "phase", "defeat")], 25.0)
	groups.append({"name": "7 · 综合防守", "cases": [combined, no_air, empty]})
	return groups

static func stationary() -> Dictionary:
	var c = base()
	c.routes.main = [Vector2(4, 3), Vector2(11, 3)]
	c.enemies.soldier.max_hp = 10000.0
	c.enemies.soldier.speed = 0.0
	c.enemies.soldier.attack = 0.0
	c.waves = [{"time": 0.0, "count": 1, "interval": 1.0, "enemy": "soldier", "route": "main"}]
	return c

static func create() -> Dictionary:
	return catalog()[6].cases[0].config.duplicate(true)
