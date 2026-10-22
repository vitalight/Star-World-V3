extends SceneTree
const Battle = preload("res://features/battle/battle.gd")
const Map = preload("res://content/scenes/scene_001/map.tscn")
const Scene = preload("res://game/battle/battle_scene.tscn")
const Fixture = preload("res://game/tests/defense_fixture.gd")
var failures := 0
var checks := 0
var history: Array = []

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func run() -> void:
	var map = Map.instantiate()
	root.add_child(map)
	check(map.errors().is_empty(), "Default map validates: " + str(map.errors()))
	check(map.cells().size() == 60 and map.routes().size() == 2, "60 cells and two paths")
	var tiles: TileMapLayer = map.get_node("Terrain")
	var cell := Vector2i(0, 0)
	for pair in [[Vector2i(0, 1), "ground", 0.0], [Vector2i(0, 0), "high", 0.42], [Vector2i(2, 2), "high", 0.42], [Vector2i(0, 3), "none", 0.0]]:
		tiles.set_cell(cell, 0, pair[0])
		var config: Dictionary = map.configuration()
		check(config.terrain.get(cell, "none") == pair[1], "Tile edit changes deployment: " + str(pair[0]))
		check(is_equal_approx(map.cells()[cell].height, pair[2]), "Tile edit changes elevation")
	tiles.erase_cell(cell)
	check(not map.cells().has(cell) and not map.configuration().terrain.has(cell), "Erasing tile removes both visual and deployment data")
	tiles.set_cell(cell, 0, Vector2i(0, 0))
	tiles.erase_cell(Vector2i(2, 1))
	check(not map.errors().is_empty(), "Route hole rejected")
	tiles.set_cell(Vector2i(2, 1), 0, Vector2i(0, 3))
	check(not map.errors().is_empty(), "Water on route rejected")
	tiles.set_cell(Vector2i(2, 1), 0, Vector2i(0, 1))
	var path: Path2D = map.get_node("Routes/upper")
	path.curve = path.curve.duplicate()
	path.curve.set_point_position(1, Vector2(608, 100))
	check(not map.errors().is_empty(), "Off-center and diagonal route rejected")
	path.curve.set_point_position(1, Vector2(800, 96))
	check(not map.errors().is_empty(), "Out of bounds route rejected")
	path.curve.set_point_position(1, Vector2(608, 96))
	map.level = map.level.duplicate(true)
	map.level.waves[0].route = "missing"
	check(not map.errors().is_empty(), "Invalid wave route rejected before constructing battle")
	map.free()
	var game = Scene.instantiate()
	root.add_child(game)
	game.set_process(false)
	for key in game.configuration.roster:
		var spec: Dictionary = game.configuration.roster[key]
		var ground := Vector2i(3,1)
		var high := Vector2i(4,2)
		var wrong: Vector2i = high if spec.role == "melee" else ground
		var correct: Vector2i = ground if spec.role == "melee" else high
		var original_cost: float = game.last_state.cost
		game.select_roster(key)
		game.select_cell(wrong)
		check(not game.hud.direction_panel.visible and not is_instance_valid(game.deployment_preview), "Wrong role terrain cannot enter pending: " + key)
		var rejected: Dictionary = game.command("deploy", [key, wrong, 0])
		check(not rejected.ok and rejected.reason == "wrong_terrain", "Battle also rejects wrong terrain: " + key)
		check(game.last_state.cost == original_cost and game.last_state.units.is_empty() and game.hud.cards[key].button.visible, "Wrong terrain does not spend or hide card: " + key)
		game.select_cell(correct)
		check(game.hud.direction_panel.visible and is_instance_valid(game.deployment_preview), "Matching role terrain allows pending: " + key)
		check(game.command("deploy", [key, correct, 0]).ok, "Matching role terrain allows deploy: " + key)
		game.reset()
	game.observed.connect(func(_state, events): history.append_array(events))
	check(game.validation_errors.is_empty() and game.battle != null, "Playable assembly validates")
	var pure = Battle.new(game.configuration)
	var cost: float = game.last_state.cost
	check(not game.command("deploy", ["guard", Vector2i(0, 0), 0]).ok, "Illegal terrain command rejected")
	check(game.last_state.cost == cost and game.presentation.actors.is_empty(), "Rejected command changes neither money nor actors")
	for args in Fixture.deployments():
		var result: Dictionary = game.command("deploy", args)
		check(result == pure.deploy(args[0], args[1], args[2]) and result.ok, "Deploy fixture " + args[0])
	check(game.presentation.actors.size() == 5, "Each deployed ID has one actor")
	for unit in game.last_state.units:
		check(game.presentation.actors[unit.id].position.is_equal_approx(game.presentation.position(unit.position)), "Feet follow map elevation")
	game.start(); pure.start()
	var pure_events: Array = pure.take_events()
	var scheduled: Array = Fixture.scheduled()
	var command_index := 0
	for tick in 600:
		var time: float = game.last_state.time
		while command_index < scheduled.size() and time + 0.00001 >= scheduled[command_index].at:
			var action: Dictionary = scheduled[command_index]
			var a: Dictionary = game.command(action.method, action.args)
			var b: Dictionary = pure.callv(action.method, action.args)
			check(a == b and a.ok, "Scheduled public command " + action.method)
			pure_events.append_array(pure.take_events())
			command_index += 1
		game.battle.advance(0.1); pure.advance(0.1)
		game.refresh(0.1)
		pure_events.append_array(pure.take_events())
		if tick % 30 == 0: check(game.last_state == pure.snapshot(), "Pure and assembled simulation agree")
		if game.last_state.phase != "running": break
	check(game.last_state.phase == "victory", "Preset wins: " + str(game.last_state))
	check(history == pure_events, "Presentation and observers receive exactly the pure battle event stream")
	for type in ["damage", "heal", "block", "skill_start", "retreat", "spawn", "finished"]:
		check(history.any(func(event): return event.type == type), "Integrated event observed: " + type)
	check(game.last_state.wave == 3 and game.last_state.spawned == 13, "Three numbered waves spawn all enemies")
	var terminal: Dictionary = game.last_state.duplicate(true)
	game.battle.advance(5); game.refresh()
	check(terminal == game.last_state, "Terminal simulation freezes")
	game.reset()
	check(game.presentation.actors.is_empty() and game.presentation.effects.is_empty() and game.presentation.departing.is_empty(), "Reset removes actors, effects, departing views")
	check(game.selected_unit == -1 and game.last_state.time == 0 and game.last_state.phase == "ready", "Reset clears selection and clock")
	game.start(); game.toggle_pause()
	game.battle.advance(4); game.refresh()
	check(game.last_state.time == 0, "Pause freezes clock")
	game.step()
	check(is_equal_approx(game.last_state.time, Battle.STEP), "Single step advances one fixed tick")
	game.reset(); game.start()
	game.battle.advance(80); game.refresh()
	check(game.last_state.phase == "defeat" and game.last_state.life == 0, "Empty defense loses")
	game.reload_level(); game.set_process(false)
	check(game.last_state.phase == "ready" and game.presentation.actors.is_empty(), "Reload restores authored content and resets battle")
	var authored = Map.instantiate()
	authored.level = authored.level.duplicate(true)
	authored.level.life = 5
	authored.level.waves[0].count = 2
	var authored_tiles: TileMapLayer = authored.get_node("Terrain")
	authored_tiles.set_cell(Vector2i(0, 0), 0, Vector2i(0, 1))
	authored_tiles.set_cell(Vector2i(1, 0), 0, Vector2i(0, 3))
	authored_tiles.erase_cell(Vector2i(9, 5))
	var edited := PackedScene.new()
	check(edited.pack(authored) == OK, "Edited map packs")
	DirAccess.make_dir_recursive_absolute("res://temp/game_test")
	check(ResourceSaver.save(edited, "res://temp/game_test/edited_map.tscn") == OK, "Edited map saves under temp")
	game.map_source = load("res://temp/game_test/edited_map.tscn")
	game.reload_level(); game.set_process(false)
	check(game.validation_errors.is_empty(), "Reload accepts edited level")
	check(game.last_state.life == 5 and game.configuration.waves[0].count == 2, "Inspector life and wave edits reach simulation")
	check(game.configuration.terrain[Vector2i(0, 0)] == "ground" and game.field.surface_height(Vector2i(0, 0)) == 0, "Saved terrain changes both simulation and 3D elevation")
	check(not game.configuration.terrain.has(Vector2i(1, 0)) and game.field.cells[Vector2i(1, 0)].appearance == "W", "Saved water renders and is not deployable")
	check(not game.field.cells.has(Vector2i(9, 5)) and not game.configuration.terrain.has(Vector2i(9, 5)), "Saved empty cell has no tile or deployment")
	authored_tiles.erase_cell(Vector2i(2, 1))
	edited = PackedScene.new(); edited.pack(authored)
	ResourceSaver.save(edited, "res://temp/game_test/invalid_map.tscn")
	game.map_source = load("res://temp/game_test/invalid_map.tscn")
	game.reload_level()
	check(game.battle == null and not game.validation_errors.is_empty() and game.last_state.is_empty(), "Invalid saved route blocks simulation and clears previous state")
	game.start()
	check(game.battle == null, "Start cannot bypass invalid configuration")
	game.map_source = Map
	game.reload_level(); game.set_process(false)
	check(game.last_state.life == 3 and game.last_state.remaining == 13, "Reload original recovers without retaining edited resources")
	game.start(); game.set_speed(2.0); game._process(0.5)
	check(is_equal_approx(game.last_state.time, 1.0), "2x advances shared simulation clock")
	game.set_speed(4.0); game._process(0.25)
	check(is_equal_approx(game.last_state.time, 2.0), "4x advances shared simulation clock")
	authored.free()
	verify_roster(game)
	var old = weakref(game)
	game.free()
	check(old.get_ref() == null, "Battle scene frees")
	await process_frame
	print("GAME INTEGRATION: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

func verify_roster(game: Node3D) -> void:
	game.reset()
	check(game.hud.cards.values().all(func(card): return card.button.visible), "Reset restores every roster card")
	game.command("deploy", ["guard", Vector2i(0, 0), 2])
	check(game.hud.cards.guard.button.visible, "Rejected deployment retains the card")
	var result: Dictionary = game.command("deploy", ["guard", Vector2i(3, 1), 2])
	check(result.ok and not game.hud.cards.guard.button.visible, "Successful deployment immediately hides its card")
	game.command("retreat", [result.id])
	check(game.hud.cards.guard.button.visible and game.hud.cards.guard.button.disabled and game.hud.cards.guard.cooldown.visible, "Retreat restores card with disabled cooldown overlay")
	game.start()
	game.battle.advance(game.last_state.redeploy.guard + 0.1); game.refresh()
	check(not game.hud.cards.guard.cooldown.visible and not game.hud.cards.guard.button.disabled, "Expired cooldown restores affordable card")
	check(game.hud.bottom.get_children() == game.hud.cards.values().map(func(card): return card.button), "Roster retains authored order")
	var snapshot: Dictionary = game.last_state.duplicate(true)
	snapshot.cost = 0
	game.hud.update_state(snapshot, "", -1, 1.0, game.configuration.deploy_limit)
	check(game.hud.cards.guard.button.visible and game.hud.cards.guard.button.disabled, "Available roster still respects insufficient cost")
	# Exercise a real death event using a deliberately fragile test-only unit.
	var fragile: Dictionary = game.configuration.duplicate(true)
	fragile.roster.guard.max_hp = 1.0
	fragile.roster.guard.defense = 0.0
	game.battle = Battle.new(fragile)
	game.reset()
	game.command("deploy", ["guard", Vector2i(0, 1), 2])
	game.start()
	var died := false
	for tick in 200:
		game.battle.advance(0.1); game.refresh(0.1)
		if game.last_state.units.is_empty():
			died = game.last_state.redeploy.guard > 0
			break
	check(died and game.hud.cards.guard.button.visible and game.hud.cards.guard.cooldown.visible, "Death restores card from the actual battle snapshot")
	game.reset()
	check(game.hud.cards.values().all(func(card): return card.button.visible and not card.cooldown.visible), "Restart clears hidden cards and cooldown masks")
