extends SceneTree
const Catalog = preload("res://game/content/content_catalog.gd")
const Battle = preload("res://features/battle/battle.gd")
const Fixture = preload("res://game/tests/chapter_fixture.gd")
var failures := 0
var checks := 0

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1; push_error(label)

func _initialize() -> void:
	var catalog = Catalog.new()
	catalog.reload()
	check(catalog.errors.is_empty(), "Catalog valid: " + "\n".join(catalog.errors))
	if not catalog.errors.is_empty(): quit(1); return
	check(catalog.characters.size() == 5 and catalog.levels.size() == 4, "Authored scope is five characters and four stages")
	check(catalog.enemies.size() == 4 and catalog.skills.size() == 5, "All authored enemies and skills registered")
	check(catalog.skill_icons("scene_002").character_011.resource_path == "res://content/ui/skill_icons/icon_01.tres", "Formal skill icon comes from skill resource")
	check(not catalog.characters.character_011.stats.skill.has("icon"), "Battle configuration excludes skill texture")
	check(catalog.appearances("scene_002").character_011.get("skill_icon") == null, "Actor appearance has no skill icon property")
	for name in ["characters", "enemies", "skills"]:
		check(not FileAccess.file_exists(Catalog.ROOT + "/" + name + ".csv"), "No duplicate CSV source for " + name)
	for id in catalog.levels:
		check(catalog.diagnostics(id).is_empty(), "Stage diagnostics: " + "\n".join(catalog.diagnostics(id)))
		var map = load(catalog.levels[id].map).instantiate()
		check(catalog.map_errors(id, map).is_empty(), "Map valid: " + "\n".join(catalog.map_errors(id, map)))
		var config: Dictionary = catalog.configuration(id, map, Fixture.operator_ids(id))
		map.free()
		var battle = Battle.new(config)
		check(Fixture.replay(battle, id).is_empty(), id + " replay commands accepted")
		var state: Dictionary = battle.snapshot()
		print(id, " phase=", state.phase, " life=", state.life, " time=", state.time, " killed=", state.killed, " units=", state.units.size())
		check(state.phase == "victory", id + " replay wins")
		if id == "scene_004": check(state.time >= 210, "Repair time gates victory")
		if id != "scene_002": check(not config.roster.has("character_012"), "Missing cat is not deployable")
		if id == "scene_003": check(not config.roster.has("character_015"), "Doctor joins after rescue")
		battle.reset(); battle.start(); battle.advance(300)
		check(battle.snapshot().phase == "defeat", id + " undefended stage loses")
		for kind in ["before", "after"]:
			if catalog.levels[id][kind].is_empty(): continue
			var story = catalog.story(catalog.levels[id][kind])
			check(story.errors().is_empty() and story.nodes.size() >= 6, id + " " + kind + " valid dialogue")
	if not "--packed" in OS.get_cmdline_user_args():
		parser_validation(catalog)
		source_reload(catalog)
	print("CHAPTER CONTENT: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

func parser_validation(catalog: RefCounted) -> void:
	var cue_path := "res://temp/chapter_one/shake_parser.md"
	var cue_text := "# Shake\n---\nbackground: background_001\nactors: character_011|character_012\nspeaker: character_011\nscreen_shake: true\nactor_shake: character_011\n> Shake\n---\nbackground: background_001\nactors: character_011\nspeaker: character_011\n> Quiet\n"
	write_text(cue_path, cue_text)
	catalog.errors.clear()
	var cue_story = catalog.story(cue_path)
	check(catalog.errors.is_empty() and cue_story.errors().is_empty(), "Authored shake metadata validates")
	check(cue_story.nodes.line_0.screen_shake and cue_story.nodes.line_0.actor_shake == ["character_011"], "Markdown exports both shake cues")
	check(not cue_story.nodes.line_1.has("screen_shake") and not cue_story.nodes.line_1.has("actor_shake"), "Shake cues do not carry into next line")
	var directed := cue_text.replace("actor_shake: character_011", "actor_shake: character_011\nactor_exit_left: character_011\nactor_exit_right: character_012")
	write_text(cue_path, directed)
	catalog.errors.clear()
	cue_story = catalog.story(cue_path)
	check(catalog.errors.is_empty() and cue_story.nodes.line_0.actor_exit_left == ["character_011"] and cue_story.nodes.line_0.actor_exit_right == ["character_012"], "Markdown preserves independent exit directions")
	check(not cue_story.nodes.line_1.has("actor_exit_left") and not cue_story.nodes.line_1.has("actor_exit_right"), "Exit directions do not inherit into next beat")
	write_text(cue_path, directed.replace("actor_exit_right: character_012", "actor_exit_right: character_011"))
	catalog.errors.clear()
	catalog.story(cue_path)
	check("\n".join(catalog.errors).contains("[actor_exit_left/actor_exit_right]"), "Opposing exit cues report content diagnostic")
	for invalid in [cue_text.replace("screen_shake: true", "screen_shake: maybe"), cue_text.replace("actor_shake: character_011", "actor_shake: character_015"), cue_text.replace("actor_shake: character_011", "actor_shake: character_011|character_011")]:
		write_text(cue_path, invalid)
		catalog.errors.clear()
		catalog.story(cue_path)
		check(not catalog.errors.is_empty() and "\n".join(catalog.errors).contains("shake]"), "Invalid authored cue reports its field")
	catalog.errors.clear()
	var path := "res://temp/chapter_one/parser.csv"
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string("id,name\nexample_001,\"中文,对白\n第二行\"\nexample_001,重复\nexample_002,正常\n")
	file.close()
	catalog.errors.clear()
	var rows: Array = catalog._table(path, "id,name")
	check(rows.size() == 2 and rows[0].name == "中文,对白\n第二行", "CSV preserves quoted commas, Chinese and multiline text")
	check(catalog.errors.size() == 1 and catalog.errors[0].contains(":4 [id]"), "Duplicate ID points to physical line after multiline field")
	catalog.errors.clear()
	var row := {"_file": path, "_line": 9, "hp": "NaN", "texture": "res://content/missing.tres"}
	catalog._number(row, "hp", 1)
	catalog._resource(row, "texture")
	check(catalog.errors.size() == 2 and catalog.errors[0].contains(":9 [hp]"), "Invalid numbers and missing resources report field locations")
	catalog.reload()

func source_reload(catalog: RefCounted) -> void:
	var base := "res://temp/chapter_one/edit_fixture"
	copy_fixture(base)
	var path := base + "/data/character_011.tres"
	edit_resource(path, "stats:display_name", "测试大星，中文\n第二行")
	catalog.reload(base, base + "/data")
	check(catalog.errors.is_empty() and catalog.characters.character_011.stats.name == "测试大星，中文\n第二行", "Saved TRES edit changes Chinese multiline battle name after reload")
	var story = catalog.story(catalog.levels.scene_002.before)
	check(story.nodes.line_2.speaker == "测试大星，中文\n第二行", "Story speakers resolve updated display name by stable ID")
	var previous: Dictionary = catalog.characters.character_011.stats.duplicate(true)
	path = base + "/data/skill_001.tres"
	edit_resource(path, "multiplier", 2.4)
	edit_resource(path, "description", "测试技能，中文\n第二行")
	catalog.reload(base, base + "/data")
	check(is_equal_approx(catalog.characters.character_011.stats.skill.multiplier, 2.4), "Saved nested skill edit reaches battle configuration after reload")
	check(catalog.skills.skill_001.description == "测试技能，中文\n第二行", "Skill resource preserves multiline Chinese description")
	check(is_equal_approx(previous.skill.multiplier, 1.8), "Reload does not mutate a previously assembled battle configuration")
	edit_resource(path, "icon", load("res://content/ui/skill_icons/icon_16.tres"))
	catalog.reload(base, base + "/data")
	check(catalog.skill_icons("scene_002").character_011.resource_path == "res://content/ui/skill_icons/icon_16.tres", "Saved skill icon edit reloads independently of actor appearance")
	edit_resource(base + "/data/character_012.tres", "stats:skill_spec", fresh(path))
	catalog.reload(base, base + "/data")
	check(catalog.skill_icons("scene_002").character_012.resource_path == catalog.skill_icons("scene_002").character_011.resource_path, "Characters sharing a skill use the same skill icon")
	edit_resource(base + "/data/enemy_001.tres", "stats:attack", 72.0)
	catalog.reload(base, base + "/data")
	check(catalog.levels.scene_002.enemies.enemy_001.attack == 72.0, "Saved enemy stat edit reaches authored waves after reload")
	var appearances: Dictionary = catalog.appearances("scene_002")
	edit_resource(base + "/data/character_011.tres", "appearance:height", 1.75)
	catalog.reload(base, base + "/data")
	check(catalog.appearances("scene_002").character_011 != appearances.character_011, "Reload also bypasses nested appearance cache")
	check(is_equal_approx(catalog.appearances("scene_002").character_011.height, 1.75), "Saving character file reloads its embedded appearance")
	path = base + "/waves.csv"
	write_text(path, FileAccess.get_file_as_string(path).replace(",main,", ",missing_route,"))
	catalog.reload(base, base + "/data")
	var map = load(catalog.levels.scene_002.map).instantiate()
	check("\n".join(catalog.map_errors("scene_002", map)).contains("[route]"), "Saved invalid wave route prevents battle with field diagnostic")
	map.free()
	var bad_story := base + "/bad.md"
	write_text(bad_story, "# 错误剧情\n---\nbackground: missing\nactors: character_011\nspeaker: character_099\n> 中文正文\n> 第二行\n")
	catalog.errors.clear(); story = catalog.story(bad_story)
	check(catalog.errors.size() == 2 and story.nodes.line_0.text == "中文正文\n第二行", "Markdown preserves multiline text and validates scene references")
	resource_validation(catalog, base)
	catalog.reload()

func write_text(path: String, text: String) -> void:
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(text)
	file.close()

func fresh(path: String):
	return ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE_DEEP)

func edit_resource(path: String, field: String, value) -> void:
	var resource = fresh(path)
	resource.set_indexed(NodePath(field), value)
	check(ResourceSaver.save(resource, path) == OK, "Inspector-compatible resource save: " + field)

func copy_fixture(base: String) -> void:
	var paths := [Catalog.DATA + "/actors.tres"]
	var library = fresh(paths[0])
	for actor in library.characters + library.enemies:
		paths.append(actor.resource_path)
	for skill in library.skills: paths.append(skill.resource_path)
	for path in paths:
		var text := FileAccess.get_file_as_string(path)
		for dependency in paths: text = text.replace(dependency, fixture_path(base, dependency))
		write_text(fixture_path(base, path), text)
	for name in ["levels", "waves", "backgrounds", "player_roster"]:
		write_text(base + "/" + name + ".csv", FileAccess.get_file_as_string(Catalog.ROOT + "/" + name + ".csv"))

func fixture_path(base: String, path: String) -> String:
	return path.replace(Catalog.DATA, base + "/data")

func resource_validation(catalog: RefCounted, base: String) -> void:
	copy_fixture(base)
	var path := base + "/data/skill_001.tres"
	edit_resource(path, "icon", null)
	catalog.reload(base, base + "/data")
	check("\n".join(catalog.errors).contains("icon:"), "Missing skill icon blocks content with field diagnostic")
	copy_fixture(base)
	edit_resource(path, "cost_gain", -1.0)
	catalog.reload(base, base + "/data")
	check("\n".join(catalog.diagnostics("scene_002")).contains("skill_001.tres [skill] cost_gain"), "Negative skill field blocks stages with resource path and field")
	edit_resource(path, "cost_gain", 0.0)
	edit_resource(path, "required", NAN)
	catalog.reload(base, base + "/data")
	check("\n".join(catalog.errors).contains("required"), "Non-finite skill value rejected")
	copy_fixture(base)
	path = base + "/data/character_011.tres"
	edit_resource(path, "stats:max_hp", INF)
	catalog.reload(base, base + "/data")
	check("\n".join(catalog.errors).contains("max_hp"), "Non-finite actor value rejected")
	copy_fixture(base)
	path = base + "/data/actors.tres"
	var library = fresh(path)
	library.characters.append(library.characters[0])
	ResourceSaver.save(library, path)
	catalog.reload(base, base + "/data")
	check("\n".join(catalog.errors).contains("[content_id]"), "Duplicate registered actor ID rejected")
	copy_fixture(base)
	library = fresh(path)
	library.skills.append(library.skills[0])
	ResourceSaver.save(library, path)
	catalog.reload(base, base + "/data")
	check("\n".join(catalog.errors).contains("[content_id]"), "Duplicate registered skill ID rejected")
	copy_fixture(base)
	library = fresh(path)
	library.skills.remove_at(0)
	ResourceSaver.save(library, path)
	catalog.reload(base, base + "/data")
	check("\n".join(catalog.errors).contains("[skill_spec]"), "Unregistered skill reference rejected")
	copy_fixture(base)
	edit_resource(base + "/data/character_011.tres", "appearance", null)
	catalog.reload(base, base + "/data")
	check("\n".join(catalog.errors).contains("[appearance]"), "Missing appearance blocks stages")
	copy_fixture(base)
	edit_resource(base + "/data/enemy_001.tres", "stats", null)
	catalog.reload(base, base + "/data")
	check("\n".join(catalog.errors).contains("[stats]"), "Missing enemy stats rejected")
	ResourceSaver.save(Resource.new(), path)
	catalog.reload(base, base + "/data")
	check("\n".join(catalog.errors).contains("[library]"), "Wrong resource type rejected")
