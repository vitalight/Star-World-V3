extends SceneTree
const Model = preload("res://devtools/balance_editor/editor_model.gd")
const ROOT := "res://temp/balance_fixture/"
var failures := 0

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(ROOT + "data"))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(ROOT + "campaign"))
	for file in DirAccess.get_files_at("res://content/data"):
		if not file.ends_with(".tres"): continue
		var text := FileAccess.get_file_as_string("res://content/data/" + file)
		text = text.replace("res://content/data/", ROOT + "data/")
		var output := FileAccess.open(ROOT + "data/" + file, FileAccess.WRITE)
		output.store_string(text)
		output.close()
	for file in ["levels.csv", "waves.csv"]:
		var input := FileAccess.get_file_as_bytes("res://content/campaign/" + file)
		var output := FileAccess.open(ROOT + "campaign/" + file, FileAccess.WRITE)
		output.store_buffer(input)
		output.close()
	var model = Model.new()
	model.data_dir = ROOT + "data/"
	model.campaign_dir = ROOT + "campaign/"
	check(model.load_all(), "fixture load " + str(model.errors))
	check(model.validate().is_empty(), "current content validates: " + str(model.validate()))
	var level: Dictionary
	for row in model.levels.rows:
		if row.values.id == "scene_0101B": level = row; break
	model.levels.set_value(level, "life", "7")
	model.table_dirty = true
	var wave: Dictionary
	for row in model.waves.rows:
		if row.values.level == "scene_0101B": wave = row; break
	model.waves.set_value(wave, "count", "4")
	var character = model.actors["character_011"]
	character.stats.attack = 123
	model.mark_resource(character.resource_path)
	var enemy = model.actors["enemy_001"]
	enemy.stats.max_hp = 333
	model.mark_resource(enemy.resource_path)
	var skill = model.skills["skill_001"]
	skill.multiplier = 2.1
	model.mark_resource(skill.resource_path)
	var problems: PackedStringArray = model.save_all()
	check(problems.is_empty(), "save changes " + str(problems))
	var reloaded = Model.new()
	reloaded.data_dir = model.data_dir
	reloaded.campaign_dir = model.campaign_dir
	check(reloaded.load_all(), "reload")
	check(reloaded.actors["character_011"].stats.attack == 123, "character saved")
	check(reloaded.actors["enemy_001"].stats.max_hp == 333, "enemy saved")
	check(is_equal_approx(reloaded.skills["skill_001"].multiplier, 2.1), "skill saved")
	check(reloaded.actors["character_011"].appearance != null and reloaded.actors["character_011"].stats.skill_spec != null, "actor references retained")
	for row in reloaded.levels.rows:
		if row.values.id == "scene_0101B": check(row.values.life == "7", "level saved")
	for row in reloaded.waves.rows:
		if row.values.id == wave.values.id: check(row.values.count == "4", "wave saved")
	# Reject invalid numbers and routes without touching files.
	reloaded.levels.rows[1].values.life = "-1"
	check(not reloaded.validate().is_empty(), "negative life rejected")
	reloaded.levels.rows[1].values.life = "7"
	var first: Dictionary = reloaded.waves.rows[0]
	first.values.route = "missing"
	check(not reloaded.validate().is_empty(), "invalid route rejected")
	first.values.route = "main"
	var air_row: Dictionary
	for row in reloaded.waves.rows:
		if row.values.level == "scene_0102B" and row.values.route == "air":
			air_row = row
			break
	check(not air_row.is_empty(), "fixture has flying route")
	var old_enemy: String = air_row.values.enemy
	air_row.values.enemy = "enemy_001"
	check(not reloaded.validate().is_empty(), "ground enemy on flying route rejected")
	air_row.values.enemy = old_enemy
	# Conflict must leave external content intact.
	var data_path := ROOT + "data/character_011.tres"
	var external := FileAccess.get_file_as_string(data_path) + "\n"
	var file := FileAccess.open(data_path, FileAccess.WRITE)
	file.store_string(external)
	file.close()
	reloaded.actors["character_011"].stats.attack = 200
	reloaded.mark_resource(data_path)
	check(not reloaded.save_all().is_empty(), "external changes detected")
	check(FileAccess.get_file_as_string(data_path) == external, "external content preserved")
	print("BALANCE MODEL: ", failures, " failures")
	quit(1 if failures else 0)
