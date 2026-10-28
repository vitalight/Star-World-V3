extends SceneTree
const Fixture = preload("res://game/tests/defense_fixture.gd")
var checks := 0
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)
func live_effects(game, kind: String) -> Array:
	return game.presentation.effects.filter(func(effect): return is_instance_valid(effect) and not effect.is_queued_for_deletion() and effect.kind == kind)
func capture(name: String, game, kind: String) -> void:
	var effects := live_effects(game, kind)
	for effect in effects: effect.sprite.hide()
	for frame in 4: await process_frame
	await RenderingServer.frame_post_draw
	var baseline := root.get_texture().get_image()
	for effect in effects: effect.sprite.show()
	for frame in 4: await process_frame
	await RenderingServer.frame_post_draw
	var rendered := root.get_texture().get_image()
	var center: Vector2 = game.camera.unproject_position(effects[0].position)
	center *= Vector2(rendered.get_size()) / root.get_visible_rect().size
	var region := Rect2i(Vector2i(center) - Vector2i(60,60), Vector2i(120,120)).intersection(Rect2i(Vector2i.ZERO, rendered.get_size()))
	var visible := 0
	for y in range(region.position.y, region.end.y):
		for x in range(region.position.x, region.end.x):
			var color := rendered.get_pixel(x,y)
			var old := baseline.get_pixel(x,y)
			if absf(color.r - old.r) + absf(color.g - old.g) + absf(color.b - old.b) > 0.08: visible += 1
	check(visible > 6, "Rendered " + kind + " visibly changes the battlefield: " + str(visible) + " pixels")
	rendered.save_png("res://temp/verification/" + name + ".png")
func run() -> void:
	root.size = Vector2i(1280,800)
	var game = load("res://game/tests/sample_battle_fixture.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	for frame in 6: await process_frame
	for direction in [Vector3.RIGHT, Vector3.LEFT]:
		var effect = game.presentation.spawn_effect(game.presentation.effect_texture, "slash", 1.3)
		var origin: Vector3 = game.camera.global_position - game.camera.global_basis.z * 5.0
		effect.play_slash(origin, origin + game.camera.global_basis * direction)
		check((-effect.sprite.global_basis.x.normalized()).dot(game.camera.global_basis * direction) > 0.99, "Slash texture faces its target on either side")
		effect.queue_free()
	for args in Fixture.deployments(): game.command("deploy", args)
	game.start()
	var seen := {}
	var frozen_tested := false
	var captured := {}
	for tick in 450:
		game.battle.advance(0.05)
		var events: Array = game.battle.take_events()
		# Use the same adapter entry as game.refresh, observing the genuine event batch.
		var state: Dictionary = game.battle.snapshot()
		game.presentation.sync(state, events, 0.05)
		game.last_state = state
		for event in events:
			if event.type == "attack_start":
				var source: Dictionary = game.presentation.combatants.get(event.source, {})
				if source.get("role", "") == "healer":
					check(not game.presentation.projectiles.has(event.source), "Healing never fires an offensive projectile")
				else:
					var ranged: bool = source.get("role", "") == "ranged" if event.friendly else source.get("ranged", false)
					var kind := "projectile" if ranged else "slash"
					seen[("friendly_" if event.friendly else "enemy_") + kind] = true
					check(not live_effects(game,kind).is_empty(), "Real attack creates " + kind)
			elif event.type == "damage":
				seen.impact = true
				check(not live_effects(game,"impact").is_empty(), "Every damage event creates an impact, including lethal hits")
				check(not game.presentation.projectiles.has(event.source), "Damage consumes the matching projectile")
			elif event.type == "miss":
				check(not game.presentation.projectiles.has(event.source), "Miss cancels the projectile without an impact")
			elif event.type == "heal":
				seen.heal = true
				check(not live_effects(game,"heal").is_empty(), "Heal keeps a distinct green effect")
		for kind in ["projectile", "slash", "impact"]:
			var active := live_effects(game,kind)
			if not active.is_empty() and not captured.has(kind) and active[0].age >= (0.03 if kind == "projectile" else 0.08):
				await capture("combat_" + kind,game,kind)
				captured[kind] = true
		var bullets := live_effects(game,"projectile")
		if not frozen_tested and not bullets.is_empty() and bullets[0].age == 0:
			var bullet = bullets[0]
			var before: Vector3 = bullet.position
			var age: float = bullet.age
			game.toggle_pause(); game._process(0.1)
			check(bullet.position == before and bullet.age == age, "Paused projectile is frozen")
			game.toggle_pause(); game.set_speed(2.0)
			var before_time: float = game.last_state.time
			game._process(0.02)
			check(is_equal_approx(bullet.age - age, game.last_state.time - before_time) and bullet.age - age > 0.02 and bullet.position.distance_to(before) > 0, "2x advances projectile by simulation time")
			game.set_speed(1.0)
			frozen_tested = true
		await process_frame
		if game.last_state.phase in ["victory", "defeat"]: break
	# A tank-only lower route lets a real melee enemy survive to attack its blocker.
	game.reset()
	var config: Dictionary = game.configuration.duplicate(true)
	config.waves = [{"time": 0.0, "enemy": "soldier", "route": "lower", "count": 1, "interval": 1.0}]
	game.battle = load("res://features/battle/battle.gd").new(config)
	game.refresh()
	game.command("deploy", ["tank", Vector2i(3,4), 2]); game.start()
	for tick in 200:
		game.battle.advance(0.05)
		var events: Array = game.battle.take_events()
		game.presentation.sync(game.battle.snapshot(),events,0.05)
		for event in events:
			if event.type == "attack_start" and not event.friendly:
				seen.enemy_slash = true
				check(not live_effects(game,"slash").is_empty(), "Blocking melee enemy emits a real slash")
		await process_frame
		if seen.has("enemy_slash"): break
	for kind in ["friendly_projectile", "friendly_slash", "enemy_projectile", "enemy_slash", "impact", "heal"]:
		check(seen.has(kind), "Observed combat coverage: " + kind)
	check(frozen_tested and captured.size() == 3, "Three effect types rendered and clock verified")
	game.reset()
	await process_frame
	check(game.presentation.effects.is_empty() and game.presentation.projectiles.is_empty() and game.presentation.combatants.is_empty(), "Reset clears all combat effects and identities")
	game.free()
	await process_frame
	print("COMBAT EFFECTS: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
