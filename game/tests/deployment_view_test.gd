extends SceneTree
## Real GUI pointer gestures, simulation-driven foot bars, and unwarped billboards.
const Scene = preload("res://devtools/game_test/game_workspace.tscn")
var game: Node3D
var failures := 0
var checks := 0
func _initialize() -> void:
	call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)
func settle() -> void:
	for frame in 5: await process_frame
func shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://temp/verification/" + name + ".png")
func mouse(point: Vector2, pressed: bool, button := MOUSE_BUTTON_LEFT) -> void:
	var event := InputEventMouseButton.new()
	event.position = point; event.global_position = point; event.button_index = button; event.pressed = pressed
	root.push_input(event,true)
	await process_frame
func motion(point: Vector2, relative: Vector2) -> void:
	var event := InputEventMouseMotion.new()
	event.position = point; event.global_position = point; event.relative = relative; event.button_mask = MOUSE_BUTTON_MASK_LEFT
	root.push_input(event,true)
	await process_frame
func key(code: Key) -> void:
	for down in [true,false]:
		var event := InputEventKey.new(); event.keycode = code; event.pressed = down
		root.push_input(event,true)
		await process_frame
func click(button: Button) -> void:
	var point := button.get_global_rect().get_center()
	await mouse(point,true); await mouse(point,false)
	await settle()
func find_button(node: Node, text: String) -> Button:
	for child in node.get_children():
		if child is Button and child.text == text: return child
		var found := find_button(child,text)
		if found: return found
	return null
func cell_point(cell: Vector2i) -> Vector2:
	return game.camera.unproject_position(Vector3(cell.x,game.field.surface_height(cell),cell.y))
func begin_drag(key: String, target: Vector2) -> void:
	var from: Vector2 = game.hud.cards[key].button.get_global_rect().get_center()
	await mouse(from,true)
	await motion(from + Vector2(-24,-24),Vector2(-24,-24))
	await settle()
	await motion(target,target - from - Vector2(-24,-24))
	await settle()
func drag_to(key: String, target: Vector2) -> void:
	await begin_drag(key,target)
	await mouse(target,false)
	await settle()
func overlay_cells(kind: String) -> Array:
	return game.overlays.get_children().filter(func(child): return child.get_meta("overlay_kind", "") == kind).map(func(child): return child.get_meta("cell"))
func run() -> void:
	root.size = Vector2i(1280,800)
	change_scene_to_packed(Scene)
	await settle()
	game = current_scene.game
	game.set_process(false)
	var regions := {"guard":Vector2(940.5,0), "tank":Vector2(0,313.5), "sniper":Vector2(627,313.5), "caster":Vector2(0,627), "medic":Vector2(940.5,627)}
	for key in game.hud.cards:
		var icon: TextureRect = game.hud.cards[key].class_icon
		check(icon.texture is AtlasTexture and icon.texture.region.position == regions[key], "Roster uses the assigned profession atlas region: " + key)
		check(icon.texture == game.appearances[key].class_icon and icon.mouse_filter == Control.MOUSE_FILTER_IGNORE, "Profession art is injected without intercepting drag: " + key)
	var before: float = game.last_state.cost
	var point := cell_point(Vector2i(3,1))
	await begin_drag("guard",point)
	check(not game.hud.dragged_roster.is_empty(),"Dragging card starts the deployment gesture")
	check(game.candidate == Vector2i(3,1) and game.selected_roster == "guard", "Dragging previews authored grid cell")
	check(game.last_state.units.is_empty() and not game.deployment_pending,"Hovering does not deploy or open confirmation")
	check(not overlay_cells("deployable").is_empty() and overlay_cells("deployable").all(func(cell): return game.battle.deployment_check("guard",cell,game.facing).ok), "Green overlay contains only genuinely deployable cells")
	check(not overlay_cells("attack_range").is_empty(), "Legal drag hover shows orange attack range")
	await motion(cell_point(Vector2i(0,0)),Vector2(-100,-100)); await settle()
	check(overlay_cells("attack_range").is_empty() and not overlay_cells("deployable").is_empty(), "Wrong-terrain hover keeps green positions without orange range")
	await shot("game_dragging_invalid")
	await motion(Vector2(350,760),Vector2(0,400)); await settle()
	check(overlay_cells("attack_range").is_empty(), "Off-map drag has no attack preview")
	await motion(point,Vector2(100,-400)); await settle()
	await shot("game_dragging")
	await mouse(point,false); await settle()
	check(game.deployment_pending and game.candidate == Vector2i(3,1),"Release on tile opens facing selection")
	check(game.last_state.cost == before,"Dropping waits for facing confirmation without charging")
	check(is_instance_valid(game.deployment_preview) and game.deployment_preview.position.distance_to(game.presentation.position(Vector2(3,1))) < 0.001, "Pending operator stands at the chosen tile")
	await mouse(point,true); await mouse(point,false)
	check(game.last_state.units.is_empty(), "Unchosen facing cannot confirm with a battlefield click")
	for direction in 4:
		var offset: Vector2 = [Vector2(90,0),Vector2(0,80),Vector2(-90,0),Vector2(0,-80)][direction]
		await motion(point + offset,offset)
		check(game.facing == direction and game.candidate == Vector2i(3,1), "Mouse aiming rotates without moving pending tile: " + str(direction))
		check(game.deployment_preview.compass.visible and game.deployment_preview.compass.basis.x.dot([Vector3.RIGHT,Vector3.BACK,Vector3.LEFT,Vector3.FORWARD][direction]) > 0.999, "Pending compass tracks mouse-selected facing")
		check(game.deployment_preview.sprite.flip_h == (direction == 0) and game.deployment_preview.sprite.texture == game.appearances.guard.poses[1 if direction == 3 else 0], "Pending pose follows selected facing")
	await motion(point + Vector2(-90,0),Vector2(-90,0))
	await shot("game_pending_deployment")
	await mouse(point + Vector2(90,0),true); await mouse(point + Vector2(90,0),false)
	await settle()
	check(not is_instance_valid(game.deployment_preview), "Confirmation removes the presentation-only preview")
	check(game.last_state.units.size() == 1 and not game.hud.cards.guard.button.visible,"Mouse direction confirmation deploys and removes card")
	check(game.last_state.units[0].facing == 0, "Click position overrides previously hovered deployment direction")
	if not game.presentation.actors.has(1):
		print("Deployment missing after drag confirmation")
		quit(1); return
	check(overlay_cells("attack_range").is_empty() and overlay_cells("deployable").is_empty(), "Successful deployment immediately clears orange and green overlays")
	var actor = game.presentation.actors[1]
	var actor_point: Vector2 = game.camera.unproject_position(actor.visual_position() + game.camera.global_basis.y * 0.5)
	await mouse(actor_point,true); await mouse(actor_point,false); await settle()
	check(game.selected_unit == 1 and not overlay_cells("attack_range").is_empty(), "Clicking deployed operator displays orange attack range")
	check(overlay_cells("attack_range").all(func(cell): return preload("res://features/battle/combat.gd").range_cells(game.last_state.units[0]).has(cell)), "Selected range follows the operator position and facing")
	check(overlay_cells("deployable").is_empty(), "Inspecting operator does not show deployment highlights")
	await shot("game_selected_range")
	await key(KEY_ESCAPE)
	check(overlay_cells("attack_range").is_empty(), "Cancelling selection clears inspected range")
	check(actor.sprite.scale == Vector3.ONE and actor.sprite.billboard == BaseMaterial3D.BILLBOARD_ENABLED,"Full billboard without compensating stretch")
	var feet: Vector2 = game.camera.unproject_position(actor.position)
	var bars: Vector2 = game.camera.unproject_position(actor.health_bar.global_position)
	check(bars.y > feet.y,"Readouts are below the operator feet")
	check(actor.health_image.get_pixel(2,2).g > actor.health_image.get_pixel(2,2).r,"Life is green")
	check(actor.health_image.get_pixel(2,8).b > actor.health_image.get_pixel(2,8).r,"SP is blue")
	check(actor.health_image.get_pixel(2,14).a == 0,"Inactive skill has no duration bar")
	game.start(); game.command("activate_skill",[1])
	check(actor.health_image.get_pixel(2,14).a > 0,"Real skill event adds duration bar")
	game.battle.advance(0.5); game.refresh(0.5)
	check(actor.last_bars.z > 0 and actor.last_bars.z < 1,"Duration bar follows remaining simulation time")
	game.toggle_pause()
	var frozen: PackedByteArray = actor.health_image.get_data()
	game._process(0.5)
	check(actor.health_image.get_data() == frozen,"Pause freezes foot readouts")
	await key(KEY_ESCAPE)
	await shot("game_foot_bars")
	game.toggle_pause()
	game.battle.advance(5.0); game.refresh(5.0)
	check(actor.health_image.get_pixel(2,14).a == 0,"Expired skill removes its duration bar")
	var occupied_cost: float = game.last_state.cost
	await drag_to("tank",cell_point(Vector2i(3,1)))
	check(not overlay_cells("deployable").has(Vector2i(3,1)) and overlay_cells("attack_range").is_empty() and not game.deployment_pending, "Occupied cell is neither green nor eligible for orange preview")
	check(game.last_state.units.size() == 1 and game.last_state.cost == occupied_cost and game.hud.cards.tank.button.visible,"Occupied drop is rejected by battle without charging")
	await key(KEY_ESCAPE)
	game.reset(); await settle()
	await drag_to("guard",cell_point(Vector2i(0,0)))
	check(not game.deployment_pending and not is_instance_valid(game.deployment_preview), "Melee cannot enter pending placement on high ground")
	check(game.last_state.units.is_empty() and game.last_state.cost == before and game.hud.cards.guard.button.visible,"Invalid terrain drop cannot spend or deploy")
	await key(KEY_ESCAPE)
	check(not is_instance_valid(game.deployment_preview), "Cancelling pending placement removes the actor preview")
	for roster_key in ["sniper", "caster", "medic"]:
		await drag_to(roster_key,cell_point(Vector2i(3,1)))
		check(not game.deployment_pending and not is_instance_valid(game.deployment_preview) and game.hud.cards[roster_key].button.visible and overlay_cells("attack_range").is_empty(), "Ranged/healer ground drop is rejected before pending: " + roster_key)
		check(game.last_state.units.is_empty() and game.last_state.cost == before and game.hud.notice.text.contains("高台"), "Rejected ground drop preserves cost and explains restriction")
		await key(KEY_ESCAPE)
		await drag_to(roster_key,cell_point(Vector2i(4,2)))
		check(game.deployment_pending and is_instance_valid(game.deployment_preview) and not overlay_cells("attack_range").is_empty(), "Ranged/healer may enter pending on high ground with orange range: " + roster_key)
		await key(KEY_ESCAPE)
	await drag_to("guard",Vector2(350,760))
	check(game.selected_roster.is_empty() and not game.deployment_pending,"Drop outside map cancels")
	await begin_drag("guard",point)
	await key(KEY_ESCAPE)
	await mouse(point,false); await settle()
	check(game.hud.dragged_roster.is_empty() and game.selected_roster.is_empty(),"Esc cancels drag and clears preview")
	await begin_drag("guard",point)
	await mouse(point,true,MOUSE_BUTTON_RIGHT); await mouse(point,false,MOUSE_BUTTON_RIGHT)
	await mouse(game.hud.cards.guard.button.get_global_rect().get_center(),false)
	await settle()
	check(game.hud.dragged_roster.is_empty() and game.selected_roster.is_empty(),"Right click cancels without reselecting the dragged card")
	await begin_drag("guard",point)
	game.reset()
	await mouse(point,false); await settle()
	check(game.hud.dragged_roster.is_empty() and game.last_state.units.is_empty() and not game.deployment_pending,"Reset cancels an in-progress placement")
	await key(KEY_F3); await settle()
	await drag_to("guard",current_scene.debug_window.get_global_rect().get_center())
	check(game.last_state.units.is_empty() and not game.deployment_pending,"Drop onto embedded debug cannot reach battlefield")
	await key(KEY_F3)
	for dimensions in [Vector2i(1280,800),Vector2i(960,600),Vector2i(1600,900)]:
		root.size = dimensions
		await settle(); game.fit_camera()
		await drag_to("guard",cell_point(Vector2i(3,1)))
		check(game.deployment_pending and game.candidate == Vector2i(3,1),"Drag projection adapts to " + str(dimensions))
		await motion(cell_point(Vector2i(3,1)) + Vector2(75,0),Vector2(75,0))
		check(game.facing == 0 and game.direction_chosen and is_instance_valid(game.deployment_preview), "Pending mouse facing adapts to " + str(dimensions))
		check(not game.hud.info_panel.visible and not game.hud.retreat_button.visible and not game.hud.skill_button.visible, "Pending deployment has no operator details or deployed actions")
		check(game.hud.deployment_cancel_button.visible and root.get_visible_rect().encloses(game.hud.deployment_cancel_button.get_global_rect()), "Pending retreat icon is visible and accessible")
		check(not game.deployment_preview.skill_hint.visible, "Pending operator has no ready skill marker")
		await shot("game_pending_%dx%d" % [dimensions.x,dimensions.y])
		var cancel_point: Vector2 = game.hud.deployment_cancel_button.get_global_rect().get_center()
		await mouse(cancel_point,true); await mouse(cancel_point,false); await settle()
		check(not game.deployment_pending and not game.hud.deployment_cancel_button.visible and not is_instance_valid(game.deployment_preview), "Nearby retreat icon cancels pending deployment")
		check(game.last_state.units.is_empty() and game.last_state.cost == before and game.hud.cards.guard.button.visible, "Cancellation preserves fees and roster")
		for direction in 4:
			game.select_roster("guard"); game.select_cell(Vector2i(3,1)); await settle()
			var origin := Vector3(3,game.field.surface_height(Vector2i(3,1)),1)
			var center: Vector2 = game.camera.unproject_position(origin)
			var vector: Vector3 = [Vector3.RIGHT,Vector3.BACK,Vector3.LEFT,Vector3.FORWARD][direction]
			var target: Vector2 = center + (game.camera.unproject_position(origin + vector) - center).normalized() * 85
			await mouse(target,true); await mouse(target,false); await settle()
			check(game.last_state.units.size() == 1 and game.last_state.units[0].facing == direction and not game.deployment_pending and not game.hud.deployment_cancel_button.visible, "Direct click chooses and confirms facing %d at %s" % [direction,dimensions])
			game.reset(); await settle()
	game.select_roster("guard"); game.select_cell(Vector2i(3,1)); await settle()
	var old_preview: WeakRef = weakref(game.deployment_preview)
	game.reload_level(); await settle()
	check(not game.deployment_pending and not game.hud.deployment_cancel_button.visible and old_preview.get_ref() == null, "Reload clears pending state, cancel button and preview")
	check(game.last_state.units.is_empty() and game.last_state.cost == before, "Reload during pending keeps a fresh uncharged battlefield")
	print("DEPLOYMENT VIEW: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
