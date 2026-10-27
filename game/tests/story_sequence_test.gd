extends SceneTree
const Catalog = preload("res://game/content/content_catalog.gd")
const View = preload("res://features/story/story_view.gd")
var checks := 0
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(label)
func run() -> void:
	var catalog = Catalog.new()
	catalog.reload()
	check(catalog.errors.is_empty(), "Campaign sources load")
	check(catalog.levels.size() == 9, "Nine independent chapter stages")
	var scripts: Array = []
	for id in catalog.levels:
		if catalog.levels[id].type != "story": continue
		var script = catalog.story(catalog.levels[id].story)
		check(script.errors().is_empty(), "Valid story: " + id)
		scripts.append(script)
	check(text(scripts[0]).contains("存档啊") and not text(scripts[0]).contains("钻了进去"), "Cat stays through first battle")
	check(text(scripts[1]).contains("一猫一怪撞入空洞") and text(scripts[1]).contains("房间深处传来怪物叫声"), "Cat disappears before control team battle")
	check(text(scripts[2]).contains("信号全乱了") and text(scripts[2]).contains("先救人"), "Tracking leads to doctor rescue")
	check(text(scripts[3]).contains("我是医生") and text(scripts[3]).contains("东方明珠"), "Doctor joins before root node battle")
	check(text(scripts[4]).contains("济州岛") and not text(scripts[4]).contains("铃铛"), "Ocean hook uses revised script")
	var portal_shakes := false
	var cat_cry_shakes := false
	for node in scripts[1].nodes.values():
		if node.text.contains("空洞突然再次震动"): portal_shakes = node.get("anim_screen_shake", false)
		if node.text.contains("小黄！！"): cat_cry_shakes = node.get("anim_actor_shake", []).has("character_011")
	check(portal_shakes, "Portal tremor has authored screen shake")
	check(cat_cry_shakes, "Emotional cat cry shakes protagonist")
	var both_exit := false
	for node in scripts[0].nodes.values():
		if node.text.contains("小黄") and node.text.contains("扑向"):
			both_exit = node.get("anim_actor_exit_right", []) == ["enemy_001", "character_012"]
	check(both_exit, "Pounce sends both actors offstage")
	var textures: Dictionary = catalog.story_textures()
	check(textures.actors.has("enemy_001") and textures.actors.enemy_001 != null, "Enemy appearance is available to story view")
	var view = View.new()
	view.configure(textures.backgrounds, textures.actors)
	root.add_child(view)
	var preceding := {}
	var warning := {}
	for node in scripts[0].nodes.values():
		if node.text.contains("我家什么时候多了个洞"): preceding = node
		if node.text == "小黄！别过去！": warning = node
	view.show_snapshot(preceding)
	var protagonist_facing: bool = view.actor_views[0].flip_h
	view.show_snapshot(warning)
	check(view.actor_views[0].flip_h == protagonist_facing, "Unlisted protagonist keeps default facing when cat is mirrored")
	check(view.actor_views[1].flip_h, "Authored cat is mirrored during warning")
	view._process(0.2)
	check(view.actor_views[0].flip_h == protagonist_facing and view.actor_views[1].flip_h, "Shake preserves both authored directions")
	for dimensions in [Vector2i(1280, 720), Vector2i(960, 600), Vector2i(1600, 900)]:
		root.size = dimensions
		await process_frame
		for script in scripts:
			var valid_backgrounds := true
			var valid_cast := true
			for node in script.nodes.values():
				view.show_snapshot(node)
				if node.type == "end": continue
				valid_backgrounds = valid_backgrounds and view.background.texture != null
				if node.speaker_actor.is_empty(): valid_cast = valid_cast and not view.speaker.visible
				if node.actors.size() == 2 and node.speaker_actor.is_empty():
					valid_cast = valid_cast and node.actors.any(func(id): return catalog.enemies.has(id))
				for index in node.actors.size():
					if catalog.enemies.has(node.actors[index]):
						valid_cast = valid_cast and view.actor_views[index].visible and view.actor_views[index].texture == textures.actors[node.actors[index]]
			check(valid_backgrounds, "Every beat has a background: " + script.title)
			check(valid_cast, "Narration label and dialogue cast: " + script.title)
		view.show_snapshot(scripts[0].nodes.line_0)
		check(view.background.texture is AtlasTexture, "Opening crop hides portal")
		var reveal_found := false
		for node in scripts[0].nodes.values():
			if node.get("framing") == "wide":
				view.show_snapshot(node)
				view._process(view.BACKGROUND_TRANSITION_DURATION)
				reveal_found = view.background.texture == textures.backgrounds.background_001
				break
		check(reveal_found, "Portal reveal restores wide background")
		var monster_revealed := false
		for node in scripts[0].nodes.values():
			if node.text.contains("怪物从空洞中爬出"):
				view.show_snapshot(node)
				monster_revealed = node.actors.has("enemy_001") and view.actor_views[0].visible
				break
		check(monster_revealed, "Monster appears at portal entrance")
		if "--capture" in OS.get_cmdline_user_args():
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://temp/chapter_one/monster_%dx%d.png" % [dimensions.x, dimensions.y])
			for node in scripts[4].nodes.values():
				if node.get("background") == "background_006" and not node.actors.is_empty():
					view.show_snapshot(node)
					break
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://temp/chapter_one/restored_%dx%d.png" % [dimensions.x, dimensions.y])
	view.queue_free()
	await process_frame
	print("STORY SEQUENCE: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
func text(script: Resource) -> String:
	var result := ""
	for node in script.nodes.values(): result += node.text + "\n"
	return result
