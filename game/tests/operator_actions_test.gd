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
func settle() -> void:
	for frame in 6: await process_frame
func click(point: Vector2) -> void:
	var motion := InputEventMouseMotion.new(); motion.position = point
	root.push_input(motion,true)
	for down in [true,false]:
		var event := InputEventMouseButton.new()
		event.position = point; event.button_index = MOUSE_BUTTON_LEFT; event.pressed = down
		root.push_input(event,true)
		await process_frame
	await settle()
func click_button(button: Button) -> void:
	await settle()
	await click(button.get_global_rect().get_center())
func select_actor(id: int) -> void:
	var actor = game.presentation.actors[id]
	await click(game.camera.unproject_position(actor.position + game.camera.global_basis.y * actor.display_height() * 0.5))
func run() -> void:
	root.size = Vector2i(1280,800)
	game = load("res://game/battle/battle_scene.tscn").instantiate()
	root.add_child(game); game.set_process(false)
	await settle()
	var deployed: Dictionary = game.command("deploy",["guard",Vector2i(3,1),2])
	game.start()
	var actor = game.presentation.actors[deployed.id]
	check(actor.skill_ready and actor.skill_hint.visible, "Full SP shows ready light on deployed operator")
	check(float(actor.billboard_material.get_shader_parameter("readiness")) > 0, "Ready operator has gold material highlight")
	await select_actor(deployed.id)
	check(game.selected_unit == deployed.id and game.hud.info_panel.visible, "Clicking deployed operator opens details")
	check(game.hud.skill_button.icon != null and not game.hud.skill_button.disabled and game.hud.skill_status.text.contains("就绪"), "Ready skill icon can be activated")
	check(game.hud.retreat_button.tooltip_text.contains("一半") and game.hud.retreat_button.tooltip_text.contains("冷却"), "Details explain refund and redeployment delay")
	for dimensions in [Vector2i(1280,800), Vector2i(960,600)]:
		root.size = dimensions; await settle(); game.fit_camera()
		check(root.get_visible_rect().encloses(game.hud.info_panel.get_global_rect()), "Operator actions fit " + str(dimensions))
	root.size = Vector2i(1280,800); await settle(); game.fit_camera()
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://temp/verification/operator_skill_ready.png")
	game.toggle_pause()
	var phase: float = actor.readiness_phase
	game._process(0.5)
	check(actor.readiness_phase == phase, "Pause freezes readiness glow")
	game.toggle_pause()
	await click_button(game.hud.skill_button)
	var active: Dictionary = game.battle.find_unit(deployed.id)
	check(active.skill_left > 0 and active.sp == 0, "Clicking the skill icon activates real skill and consumes SP")
	check(not actor.skill_hint.visible and not actor.skill_ready and float(actor.billboard_material.get_shader_parameter("readiness")) == 0, "Activation clears ready light")
	check(game.hud.skill_button.disabled and game.hud.skill_status.text.contains("持续中"), "Active skill cannot be fired again")
	await click_button(game.hud.skill_button)
	check(game.battle.find_unit(deployed.id).skill_left == active.skill_left, "Repeated disabled click does not restart skill")
	var before: float = game.last_state.cost
	await click_button(game.hud.retreat_button)
	check(game.battle.find_unit(deployed.id).is_empty() and not game.hud.info_panel.visible, "Retreat removes operator and closes its details")
	check(is_equal_approx(game.last_state.cost, minf(game.configuration.cost_cap, before + floorf(active.cost * 0.5))), "Retreat refunds half the deployment cost, respecting cap")
	check(game.hud.cards.guard.button.visible and game.hud.cards.guard.button.disabled and game.hud.cards.guard.cooldown.visible, "Retreated card returns with disabled cooldown overlay")
	check(not actor.skill_hint.visible, "Departing operator has no readiness marker")
	var cost: float = game.last_state.cost
	check(game.command("deploy",["guard",Vector2i(3,1),2]).reason == "redeploy_cooldown" and game.last_state.cost == cost, "Immediate redeployment is rejected without spending")
	game.battle.advance(active.redeploy_time - 0.1); game.refresh(active.redeploy_time - 0.1)
	check(game.hud.cards.guard.button.disabled and game.last_state.redeploy.guard > 0, "Card remains locked until cooldown ends")
	game.battle.advance(0.2); game.refresh(0.2)
	check(not game.hud.cards.guard.button.disabled and not game.hud.cards.guard.cooldown.visible, "Cooldown completion makes affordable card available")
	check(game.command("deploy",["guard",Vector2i(3,1),2]).ok, "Redeployment succeeds after cooldown")
	game.reset()
	check(game.presentation.actors.is_empty() and game.hud.cards.values().all(func(card): return card.button.visible), "Reset clears lights and restores roster")
	# Actual auto recovery, with a later wave so no enemy interferes with timing.
	var config: Dictionary = game.configuration.duplicate(true)
	config.roster.guard.skill.initial_sp = 0.0
	for wave in config.waves: wave.time += 100.0
	game.battle = Battle.new(config); game.refresh()
	deployed = game.command("deploy",["guard",Vector2i(3,1),2]); game.start()
	actor = game.presentation.actors[deployed.id]
	check(not actor.skill_hint.visible, "Uncharged operator has no ready light")
	await select_actor(deployed.id)
	check(game.hud.skill_button.disabled and game.hud.skill_status.text.contains("充能"), "Uncharged icon displays charging state")
	game.battle.advance(4.9); game.refresh(4.9)
	check(not actor.skill_hint.visible and game.hud.skill_button.disabled, "Recovery below threshold stays unavailable")
	game.battle.advance(0.2); game.refresh(0.2)
	check(actor.skill_hint.visible and not game.hud.skill_button.disabled, "Auto recovery crossing threshold lights operator and enables icon")
	await click_button(game.hud.skill_button)
	check(game.battle.find_unit(deployed.id).skill_left > 0 and not actor.skill_hint.visible, "Auto-recovered skill can be activated through icon")
	game.free(); await process_frame
	print("OPERATOR ACTIONS: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
