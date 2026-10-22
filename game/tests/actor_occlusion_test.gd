extends SceneTree
## Compare actual rendered head pixels with an isolated actor; catches terrain slicing a billboard.
const Scene = preload("res://game/battle/battle_scene.tscn")
var checks := 0
var failures := 0
var game: Node3D
func _initialize() -> void:
	call_deferred("run")
func render() -> Image:
	for frame in 3: await process_frame
	await RenderingServer.frame_post_draw
	return root.get_texture().get_image()
func check_heads(key: String, cell: Vector2i, facing: int, attacking: bool, dimensions: Vector2i) -> void:
	game.reset()
	game.command("deploy", [key,cell,facing])
	game.cancel_selection()
	var actor = game.presentation.actors[1]
	if attacking:
		var state: Dictionary = game.battle.find_unit(1)
		state.action = {"preview":true}
		actor.apply_state(state,false)
	actor.health_bar.hide()
	actor.skill_hint.hide() # Status UI is excluded from the character silhouette, like the bars.
	game.hud.hide()
	game.field.hide()
	actor.hide()
	var empty := await render()
	actor.show()
	var isolated := await render()
	var material = actor.sprite.material_override
	var mode = actor.sprite.billboard
	actor.sprite.material_override = null
	actor.sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	var reference := await render()
	actor.sprite.material_override = material
	actor.sprite.billboard = mode
	game.field.show()
	var actual := await render()
	actor.hide()
	var terrain := await render()
	actor.show()
	var feet: Vector2 = game.camera.unproject_position(actor.position) * Vector2(actual.get_size()) / root.get_visible_rect().size
	var rect := Rect2i(Vector2i(feet) - Vector2i(110,200), Vector2i(220,220)).intersection(Rect2i(Vector2i.ZERO,actual.get_size()))
	var mask: Array[Vector2i] = []
	var first_y := rect.end.y
	var last_y := rect.position.y
	for y in range(rect.position.y,rect.end.y):
		for x in range(rect.position.x,rect.end.x):
			if not isolated.get_pixel(x,y).is_equal_approx(empty.get_pixel(x,y)):
				mask.append(Vector2i(x,y))
				first_y = mini(first_y,y); last_y = maxi(last_y,y)
	var union_pixels := 0
	var matching := 0
	for y in range(rect.position.y,rect.end.y):
		for x in range(rect.position.x,rect.end.x):
			var a := not isolated.get_pixel(x,y).is_equal_approx(empty.get_pixel(x,y))
			var b := not reference.get_pixel(x,y).is_equal_approx(empty.get_pixel(x,y))
			if a or b:
				union_pixels += 1
				if a and b: matching += 1
	checks += 1
	if union_pixels == 0 or float(matching)/maxi(1,union_pixels) < 0.98:
		failures += 1
		push_error("Actor silhouette differs from an unwarped camera-parallel billboard: " + key)
	var head_end := first_y + int((last_y-first_y)*0.45)
	var head_pixels := 0
	var visible := 0
	for pixel in mask:
		if pixel.y > head_end: continue
		head_pixels += 1
		if not actual.get_pixelv(pixel).is_equal_approx(terrain.get_pixelv(pixel)): visible += 1
	var ratio := float(visible)/maxi(1,head_pixels)
	checks += 1
	if head_pixels == 0 or ratio < 0.95:
		failures += 1
		push_error("Head occluded: %s at %s, %s, attack=%s: %.1f%% visible" % [key,cell,dimensions,attacking,ratio*100])
	print("HEAD: %s %s %s attack=%s %.1f%%" % [key,cell,dimensions,attacking,ratio*100])
	actual.save_png("res://temp/verification/head_%s_%dx%d.png" % [key,dimensions.x,dimensions.y])
	if key == "guard" and dimensions == Vector2i(1280,800):
		# A real foreground wall must still occlude the actor: disabling depth
		# testing globally would pass the grass case but fail this one.
		var wall := MeshInstance3D.new()
		var box := BoxMesh.new(); box.size = Vector3(1.5,3.0,0.12)
		wall.mesh = box
		var stone := StandardMaterial3D.new(); stone.albedo_color = Color("476271")
		stone.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		wall.material_override = stone
		wall.position = actor.position + Vector3(0,1.0,0.6)
		game.world.add_child(wall)
		var behind_wall := await render()
		actor.hide()
		var wall_only := await render()
		var showing := 0
		for pixel in mask:
			if pixel.y <= head_end and not behind_wall.get_pixelv(pixel).is_equal_approx(wall_only.get_pixelv(pixel)): showing += 1
		checks += 1
		if float(showing)/maxi(1,head_pixels) > 0.1:
			failures += 1; push_error("Foreground wall no longer occludes the actor")
		wall.free(); actor.show()
		game.field.hide()
		actor.hit()
		var flashed := await render()
		checks += 1
		if flashed.get_data() == isolated.get_data():
			failures += 1; push_error("Hit flash no longer reaches the billboard material")
		actor.advance_visual(0.2)
		actor.depart(); actor.advance_visual(0.125)
		var faded := await render()
		checks += 1
		if faded.get_data() == isolated.get_data() or faded.get_data() == empty.get_data():
			failures += 1; push_error("Billboard must support a partial departure fade")
		game.field.show()
func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://temp/verification")
	game = Scene.instantiate()
	root.add_child(game)
	game.set_process(false)
	for dimensions in [Vector2i(1280,800), Vector2i(960,600), Vector2i(1600,900)]:
		root.size = dimensions
		for frame in 4: await process_frame
		game.fit_camera()
		await check_heads("guard",Vector2i(3,1),2,false,dimensions)
		await check_heads("tank",Vector2i(2,4),3,true,dimensions)
		await check_heads("caster",Vector2i(2,3),0,false,dimensions)
	game.free()
	print("ACTOR OCCLUSION: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
