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
	for id in ["scene_002", "scene_003"]:
		check(catalog.levels[id].after.is_empty(), "No separate post-battle story: " + id)
	var story = catalog.story(catalog.levels.scene_002.before)
	check(story.errors().is_empty(), "Opening framing parses")
	var textures: Dictionary = catalog.story_textures()
	var view = View.new()
	view.configure(textures.backgrounds, textures.actors)
	root.add_child(view)
	for dimensions in [Vector2i(1280, 720), Vector2i(960, 600), Vector2i(1600, 900)]:
		root.size = dimensions
		await process_frame
		for index in 3:
			view.show_snapshot(story.nodes["line_%d" % index])
			if index < 2:
				check(view.background.texture is AtlasTexture, "Opening uses close crop")
				check(view.background.texture.region.end.x < textures.backgrounds.background_001.get_width() * 0.65, "Right-side portal is outside crop")
			else:
				check(view.background.texture == textures.backgrounds.background_001, "Portal reveal restores full background")
			if "--capture" in OS.get_cmdline_user_args() and index != 1:
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png("res://temp/story_%dx%d_%d.png" % [dimensions.x, dimensions.y, index])
	view.show_snapshot(story.nodes.line_3)
	check(story.nodes.line_3.actors == ["character_012"] and view.actor_views[0].visible and not view.actor_views[1].visible, "Cat appears alone at curious look")
	check(not view.speaker.visible, "Narration has no speaker label")
	view.show_snapshot(story.nodes.line_4)
	check(view.speaker.visible and view.speaker.text == "大星", "Protagonist speaks alone after cat enters")
	var next_story = catalog.story(catalog.levels.scene_003.before)
	check(next_story.nodes.line_0.text.contains("客厅") and next_story.nodes.line_1.text.contains("撞出了空洞"), "1-2 opens with consequence of first battle")
	var final_story = catalog.story(catalog.levels.scene_004.before)
	check(final_story.nodes.line_0.text.contains("医院") and final_story.nodes.line_1.speaker_actor == "character_015", "1-3 opens with hospital rescue aftermath")
	for script in [story, next_story, final_story, catalog.story(catalog.levels.scene_004.after)]:
		var pairs_only_talk := true
		for node in script.nodes.values():
			if node.get("actors", []).size() == 2 and node.get("speaker_actor", "").is_empty(): pairs_only_talk = false
		check(pairs_only_talk, "Two actors appear together only in dialogue: " + script.title)
	view.queue_free()
	await process_frame
	print("STORY SEQUENCE: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
