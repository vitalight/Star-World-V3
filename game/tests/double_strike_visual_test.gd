extends SceneTree
const Battle = preload("res://features/battle/battle.gd")
var failures := 0
var seen: Array = []
func _initialize() -> void: call_deferred("run")
func check(value: bool, message: String) -> void:
	if not value: failures += 1; push_error(message)
func frame() -> void:
	await process_frame
	await RenderingServer.frame_post_draw
func run() -> void:
	root.size = Vector2i(1280, 800)
	var game = load("res://game/tests/sample_battle_fixture.tscn").instantiate()
	root.add_child(game); game.set_process(false)
	for i in 6: await process_frame
	var c: Dictionary = game.configuration.duplicate(true)
	var enemy_key: String = c.enemies.keys()[0]
	c.routes = {"test": [Vector2(3, 2), Vector2(0, 2)]}
	c.waves = [{"time": 0.0, "count": 1, "interval": 1.0, "enemy": enemy_key, "route": "test"}]
	c.route_warning_duration = 0.0
	c.enemies[enemy_key].speed = 0.0
	c.enemies[enemy_key].max_hp = 10000.0
	c.enemies[enemy_key].attack = 0.0
	c.roster.sniper.range = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)]
	c.roster.sniper.windup = 0.2
	c.roster.sniper.skill = load("res://content/data/skill_003.tres").configuration()
	c.roster.sniper.skill.initial_sp = c.roster.sniper.skill.required
	check(c.roster.sniper.skill.description.contains("每次攻击造成两次伤害"), "formal skill describes two hits")
	game.battle = Battle.new(c)
	game.configuration = game.battle.configuration()
	game.presentation.configuration = game.configuration
	game.observed.connect(func(_state, events): seen.append_array(events))
	check(game.command("deploy", ["sniper", Vector2i(5, 2), 2]).ok, "sniper deploys")
	game.start()
	game.battle.advance(0.1); game.refresh(0.1); await frame()
	var first = game.presentation.projectiles.values()[0] if not game.presentation.projectiles.is_empty() else null
	check(is_instance_valid(first) and not first.is_queued_for_deletion(), "first projectile is visible")
	game.battle.advance(0.1); game.refresh(0.1); await frame()
	DirAccess.make_dir_recursive_absolute("res://temp/verification")
	root.get_texture().get_image().save_png("res://temp/verification/double_first.png")
	game.battle.advance(0.05); game.refresh(0.05); await frame()
	var second = game.presentation.projectiles.values()[0] if not game.presentation.projectiles.is_empty() else null
	check(is_instance_valid(second) and second != first and not second.is_queued_for_deletion(), "second projectile follows first impact")
	game.battle.advance(0.08); game.refresh(0.08); await frame()
	root.get_texture().get_image().save_png("res://temp/verification/double_second.png")
	game.battle.advance(0.2); game.refresh(0.2); await frame()
	var shots = seen.filter(func(e): return e.type == "attack_start" and e.friendly)
	var hits = seen.filter(func(e): return e.type == "damage" and e.friendly)
	check(shots.size() == 2 and hits.size() == 2, "two shots and two hits are presented")
	if shots.size() == 2 and hits.size() == 2:
		check(shots[1].time == hits[0].time and hits[1].time > shots[1].time, "follow-up flight separates the impacts")
	game.free()
	print("DOUBLE STRIKE VISUAL: %d failures" % failures)
	quit(1 if failures else 0)
