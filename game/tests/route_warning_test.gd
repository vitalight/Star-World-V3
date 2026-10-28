extends SceneTree
const Battle = preload("res://features/battle/battle.gd")
var checks := 0
var failures := 0
var game: Node3D
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)
func render() -> Image:
	for frame in 4: await process_frame
	await RenderingServer.frame_post_draw
	return root.get_texture().get_image()
func packet_peak(rendered: Image, baseline: Image) -> int:
	var best := -1.0
	var peak := 0
	for index in 37:
		var point: Vector2 = game.camera.unproject_position(Vector3(index * 0.25,0.045,1.0))
		point *= Vector2(rendered.get_size()) / root.get_visible_rect().size
		var energy := 0.0
		for y in range(int(point.y)-2,int(point.y)+3):
			for x in range(int(point.x)-2,int(point.x)+3):
				var a := rendered.get_pixel(x,y); var b := baseline.get_pixel(x,y)
				energy += absf(a.r-b.r) + absf(a.g-b.g) + absf(a.b-b.b)
		if energy > best: best = energy; peak = index
	check(best > 0.5,"Route ribbon is visibly rendered")
	return peak
func run() -> void:
	game = load("res://game/tests/sample_battle_fixture.tscn").instantiate()
	root.add_child(game); game.set_process(false)
	for frame in 6: await process_frame
	var config: Dictionary = game.configuration.duplicate(true)
	config.life = 50
	config.waves = [{"time":0.0,"count":2,"interval":0.5,"enemy":"soldier","route":"upper","number":1},
		{"time":6.0,"count":1,"interval":1.0,"enemy":"soldier","route":"lower","number":2},
		{"time":6.0,"count":1,"interval":1.0,"enemy":"rifle","route":"upper","number":2}]
	var battle = Battle.new(config)
	check(battle.snapshot().route_warnings.is_empty(),"Ready phase does not advance warning")
	battle.start()
	check(battle.snapshot().route_warnings.size() == 1 and battle.snapshot().spawned == 0,"Start creates warning before immediate wave")
	check(battle.take_events().any(func(event): return event.type == "route_warning" and event.time == 0.0),"Warning event starts at time zero")
	battle.advance(1.99)
	check(battle.snapshot().spawned == 0 and battle.snapshot().route_warnings.size() == 1,"Full two-second warning precedes first enemy")
	battle.advance(0.01)
	check(battle.snapshot().spawned == 1 and battle.snapshot().route_warnings.is_empty(),"First enemy spawns exactly after warning completes")
	var spawn: Array = battle.take_events().filter(func(event): return event.type == "spawn")
	check(spawn.size() == 1 and is_equal_approx(spawn[0].time,2.0),"Initial spawn is delayed to two seconds")
	battle.advance(0.5)
	check(battle.snapshot().spawned == 2 and battle.snapshot().route_warnings.is_empty(),"Same-group enemy interval is preserved without replaying route")
	battle.advance(1.5)
	check(battle.snapshot().route_warnings.size() == 2 and battle.snapshot().spawned == 2,"Two routes can warn simultaneously before their group")
	battle.set_paused(true)
	var frozen: Dictionary = battle.snapshot()
	battle.advance(4.0)
	check(battle.snapshot() == frozen,"Pause freezes warning and spawn schedule")
	battle.step()
	check(battle.snapshot().time > frozen.time and battle.snapshot().spawned == 2,"Single step advances warning without early spawn")
	battle.set_paused(false); battle.advance(2.0)
	check(battle.snapshot().spawned == 4 and battle.snapshot().route_warnings.is_empty(),"Later wave spawns after its complete preview")
	battle.reset()
	check(battle.snapshot().route_warnings.is_empty() and battle.take_events().is_empty(),"Reset clears warnings and events")
	for dimensions in [Vector2i(1280,800),Vector2i(960,600),Vector2i(1600,900)]:
		root.size = dimensions
		for frame in 6: await process_frame
		game.fit_camera()
		var visual: Dictionary = game.configuration.duplicate(true)
		visual.waves = [{"time":3.0,"count":1,"interval":1.0,"enemy":"soldier","route":"upper"}]
		game.presentation.clear()
		game.battle = Battle.new(visual); game.refresh(); game.start()
		game.battle.advance(1.3); game.refresh(1.3)
		check(game.last_state.spawned == 0 and game.presentation.route_guides.size() == 1,"Guide visible before spawn at " + str(dimensions))
		var guide = game.presentation.route_guides.values()[0]
		check(guide.route_points == game.configuration.routes.upper,"Guide consumes actual edited route points")
		guide.hide(); var baseline := await render(); guide.show()
		var early := await render()
		early.save_png("res://temp/verification/route_early_%dx%d.png" % [dimensions.x,dimensions.y])
		var early_peak := packet_peak(early,baseline)
		game.battle.advance(1.0); game.refresh(1.0)
		var late := await render()
		late.save_png("res://temp/verification/route_late_%dx%d.png" % [dimensions.x,dimensions.y])
		var late_peak := packet_peak(late,baseline)
		check(late_peak > early_peak + 6,"Illuminated packet flows birth to base once: %d -> %d" % [early_peak,late_peak])
		game.toggle_pause()
		var progress: float = guide.progress
		game._process(0.5)
		check(guide.progress == progress and game.last_state.spawned == 0,"Paused render does not advance or spawn")
		game.toggle_pause(); game.set_speed(2.0)
		var time: float = game.last_state.time
		game._process(0.1)
		check(is_equal_approx(guide.progress-progress,(game.last_state.time-time)/2.0),"2x follows shared simulation clock")
		game.battle.advance(1.0); game.refresh(1.0)
		check(game.last_state.spawned == 1 and game.presentation.route_guides.is_empty(),"Completed guide is gone before enemy appears")
		game.reset()
		check(game.presentation.route_guides.is_empty(),"Reset removes route ribbon")
	var pair: Dictionary = game.configuration.duplicate(true)
	pair.waves = [{"time":0.0,"count":1,"interval":1.0,"enemy":"soldier","route":"upper"},
		{"time":0.0,"count":1,"interval":1.0,"enemy":"soldier","route":"lower"}]
	game.battle = Battle.new(pair); game.refresh(); game.start()
	check(game.presentation.route_guides.size() == 2 and game.last_state.spawned == 0,"Both route ribbons can play together")
	var old: WeakRef = weakref(game.presentation.route_guides.values()[0])
	game.reload_level(); game.set_process(false)
	check(old.get_ref() == null and game.presentation.route_guides.is_empty(),"Reload releases active route ribbons")
	game.start(); game.battle.advance(2.0); game.refresh(2.0)
	check(game.last_state.spawned == 1 and game.presentation.route_guides.is_empty(),"Restart replays a full warning and then spawns")
	game.free(); await process_frame
	print("ROUTE WARNING: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
