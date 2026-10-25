extends SceneTree
const Battle = preload("res://features/battle/battle.gd")
const BaseTests = preload("res://features/battle/tests/scenario_fixtures.gd")
var failures := 0
var checks := 0

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(label)

func _initialize() -> void:
	var config: Dictionary = BaseTests.base()
	var key: String = config.roster.keys()[0]
	config.initial_cost = 99.0
	config.cost_cap = 99.0
	config.cost_regen = 0.0
	config.roster[key].cost = 0.0
	config.roster[key].skill = {"enabled": true, "required": 5.0, "initial_sp": 5.0, "duration": 1.0, "cost_gain": 12.0}
	var battle = Battle.new(config)
	var cell: Vector2i = Vector2i.ZERO
	for candidate in config.terrain:
		if config.terrain[candidate] == "ground": cell = candidate; break
	var unit: Dictionary = battle.deploy(key, cell, 0)
	check(unit.ok, "Vanguard deploys")
	battle.start()
	check(battle.activate_skill(unit.id).ok and battle.snapshot().cost == 99, "Cost gain capped")
	check(not battle.activate_skill(unit.id).ok and battle.snapshot().cost == 99, "Duplicate activation rejected without extra cost")
	battle.reset()
	config.initial_cost = 10.0
	battle = Battle.new(config)
	unit = battle.deploy(key, cell, 0)
	battle.start(); battle.activate_skill(unit.id)
	check(battle.snapshot().cost == 22, "Cost gain applied once on activation")
	check(battle.take_events().filter(func(event): return event.type == "cost_gain").size() == 1, "Cost gain event emitted once")
	config.defend_duration = 10.0
	config.waves = []
	battle = Battle.new(config); battle.start(); battle.advance(3)
	check(battle.snapshot().phase == "running" and is_equal_approx(battle.snapshot().objective.elapsed, 3), "Empty waves wait for defense objective")
	battle.set_paused(true); battle.advance(20)
	check(is_equal_approx(battle.snapshot().objective.elapsed, 3), "Pause freezes objective")
	battle.step()
	check(battle.snapshot().objective.elapsed > 3, "Single step advances objective")
	battle.set_paused(false); battle.advance(20)
	check(battle.snapshot().phase == "victory" and battle.snapshot().objective.elapsed == 10, "Objective completes on simulation clock")
	battle.reset()
	check(battle.snapshot().objective.elapsed == 0 and battle.snapshot().phase == "ready", "Reset clears objective")
	config.waves = BaseTests.base().waves
	config.defend_duration = 0.1
	battle = Battle.new(config); battle.start(); battle.advance(2)
	check(battle.snapshot().phase == "running" and battle.snapshot().remaining > 0, "Completing repair does not bypass remaining enemies")
	var whole = Battle.new(config)
	var sliced = Battle.new(config)
	whole.start(); sliced.start()
	whole.advance(2)
	for i in 120: sliced.advance(1.0 / 60.0)
	check(whole.snapshot() == sliced.snapshot(), "Objective and battle state agree across time slices")
	battle = Battle.new(config)
	check(battle.debug_finish_victory() and battle.snapshot().phase == "victory", "Developer skip accepts ready state")
	var terminal: Dictionary = battle.snapshot()
	check(not battle.debug_finish_victory(), "Repeated developer skip rejected")
	var events: Array = battle.take_events()
	check(events.size() == 1 and events[0].type == "finished" and events[0].get("debug", false), "Developer win emits exactly one marked terminal event")
	battle.advance(60)
	check(battle.snapshot() == terminal and terminal.killed == 0, "Developer win freezes without inventing kills or advancing time")
	config.route_warning_duration = 2.0
	battle = Battle.new(config); battle.start(); battle.set_paused(true)
	check(battle.debug_finish_victory() and battle.snapshot().route_warnings.is_empty(), "Developer skip accepts paused battle and clears route warnings")
	config = BaseTests.base()
	battle = Battle.new(config); battle.start(); battle.advance(300)
	check(battle.snapshot().phase == "defeat" and not battle.debug_finish_victory(), "Developer skip cannot overwrite a completed defeat")
	print("CAMPAIGN RULES: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
