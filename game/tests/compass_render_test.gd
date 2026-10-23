extends SceneTree
## Real pixels verify transparent range ordering and opaque scene occlusion.
var checks := 0
var failures := 0
var game: Node3D
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(message)
func render() -> Image:
	for frame in 4: await process_frame
	await RenderingServer.frame_post_draw
	return root.get_texture().get_image()
func difference(a: Image, b: Image, region: Rect2i, require_cyan := false) -> int:
	var count := 0
	for y in range(region.position.y,region.end.y):
		for x in range(region.position.x,region.end.x):
			var color := a.get_pixel(x,y)
			if color.is_equal_approx(b.get_pixel(x,y)): continue
			if require_cyan and not (color.g > color.r + 0.08 and color.b > color.r + 0.03): continue
			count += 1
	return count
func run() -> void:
	game = load("res://game/battle/battle_scene.tscn").instantiate()
	root.add_child(game); game.set_process(false)
	for dimensions in [Vector2i(1280,800),Vector2i(960,600),Vector2i(1600,900)]:
		root.size = dimensions
		for frame in 6: await process_frame
		game.fit_camera()
		for key in ["guard","caster"]:
			game.reset()
			var cell := Vector2i(3,1) if key == "guard" else Vector2i(4,2)
			var result: Dictionary = game.command("deploy",[key,cell,0])
			game.select_cell(cell)
			var actor = game.presentation.actors[result.id]
			var marker: MeshInstance3D = actor.compass
			var old_position: Vector2 = game.camera.unproject_position(actor.visual_position() + Vector3.UP * 0.008)
			var center: Vector2 = game.camera.unproject_position(marker.global_position)
			check(absf(old_position.y - center.y - 20.0) < 1.0 and absf(old_position.x - center.x) < 0.1,"Compass moves up 20px without moving character")
			check(marker.global_basis.y.dot(Vector3.UP) > 0.999,"Compass is a horizontal world quad")
			check(game.overlays.get_children().any(func(child): return child.get_meta("overlay_kind","") == "attack_range"),"Actual range preview is present")
			var full := await render()
			full.save_png("res://temp/verification/compass_world_%s_%dx%d.png" % [key,dimensions.x,dimensions.y])
			game.hud.hide(); actor.sprite.hide(); actor.shadow.hide(); actor.health_bar.hide(); actor.skill_hint.hide()
			marker.hide(); var baseline := await render()
			marker.show(); var visible := await render()
			var pixel: Vector2 = center * Vector2(visible.get_size()) / root.get_visible_rect().size
			var region := Rect2i(Vector2i(pixel) - Vector2i(80,70),Vector2i(160,140)).intersection(Rect2i(Vector2i.ZERO,visible.get_size()))
			check(difference(visible,baseline,region,true) > 30,"Cyan compass remains visible above orange range fill")
			var wall := MeshInstance3D.new()
			var box := BoxMesh.new(); box.size = Vector3(1.5,1.8,0.12)
			wall.mesh = box
			var stone := StandardMaterial3D.new(); stone.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			stone.albedo_color = Color("476271"); wall.material_override = stone
			wall.position = marker.global_position + Vector3(0,0.8,0.7)
			wall.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			game.world.add_child(wall)
			var blocked := await render()
			marker.hide(); var blocked_baseline := await render()
			check(difference(blocked,blocked_baseline,region) < 3,"Foreground scene geometry occludes compass")
			blocked.save_png("res://temp/verification/compass_blocked_%s_%dx%d.png" % [key,dimensions.x,dimensions.y])
			wall.free(); game.hud.show()
	game.free()
	print("COMPASS RENDER: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
