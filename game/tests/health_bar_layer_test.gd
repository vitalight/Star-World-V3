extends SceneTree
## Verify the rendered health bar remains visible over a nearer character billboard.
const Scene = preload("res://game/tests/sample_battle_fixture.tscn")

func _initialize() -> void:
	call_deferred("run")

func render() -> Image:
	for frame in 3: await process_frame
	await RenderingServer.frame_post_draw
	return root.get_texture().get_image()

func run() -> void:
	root.size = Vector2i(1280, 800)
	var game = Scene.instantiate()
	root.add_child(game)
	game.set_process(false)
	for frame in 6: await process_frame
	game.fit_camera()
	game.command("deploy", ["guard", Vector2i(3, 1), 2])
	game.cancel_selection()
	game.hud.hide()
	var actor = game.presentation.actors[1]
	actor.sprite.hide()
	actor.compass.hide()
	actor.shadow.hide()
	var blocker := Sprite3D.new()
	var image := Image.create(128, 128, false, Image.FORMAT_RGBA8)
	image.fill(Color("b33bc2"))
	var texture := ImageTexture.create_from_image(image)
	blocker.texture = texture
	blocker.pixel_size = 0.01
	var material := ShaderMaterial.new()
	material.shader = preload("res://features/actor_view/billboard_depth.gdshader")
	material.set_shader_parameter("sprite_texture", texture)
	blocker.material_override = material
	game.world.add_child(blocker)
	blocker.global_position = actor.health_bar.global_position + game.camera.global_basis.z
	actor.health_bar.hide()
	var without_bar := await render()
	actor.health_bar.show()
	var with_bar := await render()
	blocker.hide()
	actor.health_bar.hide()
	var empty := await render()
	actor.health_bar.show()
	var bar_only := await render()
	var center: Vector2 = game.camera.unproject_position(actor.health_bar.global_position)
	var rect := Rect2i(Vector2i(center) - Vector2i(80, 35), Vector2i(160, 70)).intersection(Rect2i(Vector2i.ZERO, with_bar.get_size()))
	var bar_pixels := 0
	var visible_pixels := 0
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			var point := Vector2i(x, y)
			if not bar_only.get_pixelv(point).is_equal_approx(empty.get_pixelv(point)):
				bar_pixels += 1
				if not with_bar.get_pixelv(point).is_equal_approx(without_bar.get_pixelv(point)):
					visible_pixels += 1
	var ok := bar_pixels > 0 and float(visible_pixels) / bar_pixels > 0.95
	if not ok: push_error("Health bar obscured by foreground character: %d/%d pixels visible" % [visible_pixels, bar_pixels])
	print("HEALTH BAR LAYER: %d/%d pixels visible" % [visible_pixels, bar_pixels])
	game.free()
	quit(0 if ok else 1)
