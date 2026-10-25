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
	check(catalog.characters.size() == 5 and catalog.levels.size() == 3, "Authored scope is five characters and three stages")
	for id in catalog.levels:
		check(catalog.diagnostics(id).is_empty(), "Stage diagnostics: " + "\n".join(catalog.diagnostics(id)))
		var map = load(catalog.levels[id].map).instantiate()
		check(catalog.map_errors(id, map).is_empty(), "Map valid: " + "\n".join(catalog.map_errors(id, map)))
		var config: Dictionary = catalog.configuration(id, map)
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
			var story = catalog.story(catalog.levels[id][kind])
			check(story.errors().is_empty() and story.nodes.size() >= 6, id + " " + kind + " valid dialogue")
	if not "--packed" in OS.get_cmdline_user_args():
		parser_validation(catalog)
		source_reload(catalog)
	print("CHAPTER CONTENT: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

func parser_validation(catalog: RefCounted) -> void:
	var path := "res://temp/chapter_one/parser.csv"
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string("id,name\nexample_001,\"中文,对白\n第二行\"\nexample_001,重复\nexample_002,正常\n")
	file.close()
	catalog.errors.clear()
	var rows: Array = catalog._table(path, "id,name")
	check(rows.size() == 2 and rows[0].name == "中文,对白\n第二行", "CSV preserves quoted commas, Chinese and multiline text")
	check(catalog.errors.size() == 1 and catalog.errors[0].contains(":4 [id]"), "Duplicate ID points to physical line after multiline field")
	catalog.errors.clear()
	var row := {"_file": path, "_line": 9, "hp": "NaN", "appearance": "res://content/missing.tres"}
	catalog._number(row, "hp", 1)
	catalog._resource(row, "appearance")
	check(catalog.errors.size() == 2 and catalog.errors[0].contains(":9 [hp]"), "Invalid numbers and missing resources report field locations")
	catalog.reload()

func source_reload(catalog: RefCounted) -> void:
	var base := "res://temp/chapter_one/edit_fixture"
	DirAccess.make_dir_recursive_absolute(base)
	for name in ["characters", "skills", "enemies", "levels", "waves", "backgrounds"]:
		var file := FileAccess.open(base + "/" + name + ".csv", FileAccess.WRITE)
		file.store_string(FileAccess.get_file_as_string(Catalog.ROOT + "/" + name + ".csv")); file.close()
	var path := base + "/characters.csv"
	var contents := FileAccess.get_file_as_string(path).replace("大星", "测试大星")
	var file := FileAccess.open(path, FileAccess.WRITE); file.store_string(contents); file.close()
	catalog.reload(base)
	check(catalog.errors.is_empty() and catalog.levels.scene_002.roster.character_011.name == "测试大星", "Saved CSV edit changes battle name after reload")
	var story = catalog.story(catalog.levels.scene_002.before)
	check(story.nodes.line_1.speaker == "测试大星", "Story speakers resolve updated display name by stable ID")
	path = base + "/skills.csv"
	contents = FileAccess.get_file_as_string(path).replace(",1.8,1,0", ",2.4,1,0")
	file = FileAccess.open(path, FileAccess.WRITE); file.store_string(contents); file.close()
	catalog.reload(base)
	check(is_equal_approx(catalog.levels.scene_002.roster.character_011.skill.multiplier, 2.4), "Saved skill numeric edit reaches battle configuration after reload")
	path = base + "/waves.csv"
	contents = FileAccess.get_file_as_string(path).replace(",main,", ",missing_route,")
	file = FileAccess.open(path, FileAccess.WRITE); file.store_string(contents); file.close()
	catalog.reload(base)
	var map = load(catalog.levels.scene_002.map).instantiate()
	check("\n".join(catalog.map_errors("scene_002", map)).contains("[route]"), "Saved invalid wave route prevents battle with field diagnostic")
	map.free()
	var bad_story := base + "/bad.md"
	file = FileAccess.open(bad_story, FileAccess.WRITE)
	file.store_string("# 错误剧情\n---\nbackground: missing\nactors: character_011\nspeaker: character_099\n> 中文正文\n> 第二行\n")
	file.close()
	catalog.errors.clear(); story = catalog.story(bad_story)
	check(catalog.errors.size() == 2 and story.nodes.line_0.text == "中文正文\n第二行", "Markdown preserves multiline text and validates scene references")
	catalog.reload()
