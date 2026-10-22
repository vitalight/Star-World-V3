@tool
extends Resource
const UnitSpec = preload("res://features/battle/unit_spec.gd")
const WaveSpec = preload("res://features/battle/wave_spec.gd")
@export var life := 3
@export var initial_cost := 70.0
@export var cost_cap := 99.0
@export var cost_regen := 1.5
@export var deploy_limit := 5
@export_range(0.0, 10.0, 0.1) var route_warning_duration := 2.0
@export var roster: Dictionary[String, UnitSpec] = {}
@export var enemies: Dictionary[String, UnitSpec] = {}
@export var waves: Array[WaveSpec] = []

func configuration(terrain: Dictionary, routes: Dictionary) -> Dictionary:
	var result := {"terrain": terrain, "routes": routes, "life": life, "initial_cost": initial_cost,
		"cost_cap": cost_cap, "cost_regen": cost_regen, "deploy_limit": deploy_limit,
		"roster": {}, "enemies": {}, "waves": [], "route_warning_duration": route_warning_duration}
	for key in roster: result.roster[key] = roster[key].configuration()
	for key in enemies: result.enemies[key] = enemies[key].configuration(true)
	for wave in waves: result.waves.append(wave.configuration())
	return result

func errors(routes: Dictionary) -> PackedStringArray:
	var result := PackedStringArray()
	if life <= 0 or initial_cost < 0 or initial_cost > cost_cap or cost_regen < 0 or deploy_limit < 1:
		result.append("Level: 基地生命、费用或部署上限非法")
	if route_warning_duration < 0: result.append("Level.route_warning_duration: 路线预告时长不可为负")
	if roster.is_empty() or enemies.is_empty() or waves.is_empty(): result.append("Level: 编队、敌人和波次不能为空")
	for collection in [roster, enemies]:
		for key in collection:
			if collection[key] == null:
				result.append("Unit %s: 资源为空" % key)
			else:
				for message in collection[key].errors(): result.append("Unit %s: %s" % [key, message])
	for i in waves.size():
		var wave = waves[i]
		if wave == null:
			result.append("Wave %d: 资源为空" % i)
			continue
		if not enemies.has(wave.enemy) or not routes.has(wave.route): result.append("Wave %d: enemy / route 引用无效" % i)
		if wave.time < 0 or wave.count < 1 or wave.interval <= 0: result.append("Wave %d: 时间或数量非法" % i)
	return result
