extends SceneTree

const Catalog = preload("res://game/content/content_catalog.gd")
const Preview = preload("res://game/player/map_preview.gd")

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("地图截图需要图形渲染，请不要使用 --headless。")
		quit(1)
		return
	var catalog = Catalog.new()
	var errors: PackedStringArray = catalog.reload()
	if not errors.is_empty():
		push_error("\n".join(errors))
		quit(1)
		return
	for id in catalog.levels:
		var level: Dictionary = catalog.levels[id]
		if level.type != "battle": continue
		var scene = load(level.map)
		if not scene is PackedScene:
			push_error("无法加载地图：" + level.map)
			quit(1)
			return
		var viewport := SubViewport.new()
		viewport.size = Vector2i(1440, 900)
		viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		root.add_child(viewport)
		var world = Preview.new()
		world.map_source = scene
		viewport.add_child(world)
		for frame in 5: await process_frame
		await RenderingServer.frame_post_draw
		var output := "res://content/scenes/%s/level_preview.png" % id
		var image := viewport.get_texture().get_image()
		var error := image.save_png(output)
		viewport.queue_free()
		if error != OK:
			push_error("无法保存截图：" + output)
			quit(1)
			return
		print("已更新：", output)
	quit()
