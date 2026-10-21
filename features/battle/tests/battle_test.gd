extends SceneTree

const Battle = preload("res://features/battle/battle.gd")
var checks = 0
var failures = 0

func _initialize() -> void:
	var battle = Battle.new(fixture())
	check(not battle.deploy(-1) and not battle.deploy(1), "invalid slot rejected")
	check(battle.deploy(0) and not battle.deploy(0), "duplicate deployment rejected")
	var copy = battle.snapshot()
	copy.units.clear()
	check(battle.snapshot().units.size() == 1, "snapshot cannot mutate rules")
	check(battle.start() and not battle.start(), "wave starts only once")
	battle.advance(1.0 / 60.0)
	check(battle.snapshot().enemies[0].hp == 40, "first hit deals configured damage")
	check(battle.take_events().size() == 1 and battle.take_events().is_empty(), "attack events consumed once")
	battle.advance(0.2)
	check(battle.snapshot().enemies[0].hp == 40, "cooldown prevents continuous damage")
	battle.advance(0.5)
	check(battle.snapshot().enemies[0].hp == 20, "cooldown allows next hit")
	battle.advance(3.0)
	check(battle.snapshot().phase == "victory" and battle.snapshot().killed == 1, "killing final enemy wins")
	var terminal = battle.snapshot()
	battle.advance(60.0)
	check(battle.snapshot() == terminal and not battle.deploy(0), "finished simulation frozen")
	battle.reset()
	check(battle.snapshot().phase == "ready" and battle.snapshot().units.is_empty() and battle.snapshot().life == 3, "reset restores full initial state")
	battle.start()
	battle.advance(11.0)
	check(battle.snapshot().phase == "victory" and battle.snapshot().life == 2 and battle.snapshot().escaped == 1, "surviving leakage wins after all resolved")
	var config = fixture()
	config.life = 1
	battle = Battle.new(config)
	battle.start()
	battle.advance(11.0)
	check(battle.snapshot().phase == "defeat" and battle.snapshot().life == 0, "base depletion loses")
	config = fixture()
	config.slots = [Vector2(500, 500)]
	battle = Battle.new(config)
	battle.deploy(0)
	battle.start()
	battle.advance(1.0)
	check(battle.snapshot().enemies[0].hp == 60, "out of range targets not damaged")
	config = fixture()
	config.count = 2
	config.spawn_interval = 20.0
	battle = Battle.new(config)
	battle.deploy(0)
	battle.start()
	battle.advance(4.0)
	check(battle.snapshot().phase == "running" and battle.snapshot().remaining == 1, "waits for pending spawns before victory")
	var small = Battle.new(fixture())
	var large = Battle.new(fixture())
	small.start()
	large.start()
	for i in range(120):
		small.advance(1.0 / 60.0)
	large.advance(2.0)
	check(small.snapshot() == large.snapshot(), "time partition does not change simulation")
	config = fixture()
	config.path = [Vector2.ZERO, Vector2(10, 0), Vector2(10, 10)]
	battle = Battle.new(config)
	battle.start()
	battle.advance(1.5)
	check(battle.snapshot().enemies[0].position.distance_to(Vector2(10, 5)) < 0.01, "movement follows path corners")
	print("Battle rules: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

func fixture() -> Dictionary:
	return {"path": [Vector2.ZERO, Vector2(100, 0)], "slots": [Vector2(30, 10)], "life": 3, "count": 1, "spawn_interval": 1.0, "enemy_hp": 60, "enemy_speed": 10.0, "damage": 20, "attack_range": 60.0, "attack_interval": 0.5}

func check(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(label)
