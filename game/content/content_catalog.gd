extends RefCounted
## Source files are authoritative. Builds battle dictionaries and StoryScript resources.
const StoryScript = preload("res://features/story/story_script.gd")
const Library = preload("res://features/content_definitions/actor_library.gd")
const ROOT := "res://content/campaign"
const DATA := "res://content/data"
var errors := PackedStringArray()
var characters := {}
var skills := {}
var enemies := {}
var levels := {}
var waves: Array = []
var backgrounds := {}
var starting_operators: Array[String] = []
var recruits := {}
var departures := {}
var returns := {}
var _level_errors := {}
var _appearances := {}
var _skill_icons := {}

func reload(base := ROOT, data_base := DATA) -> PackedStringArray:
	errors.clear(); characters.clear(); skills.clear(); enemies.clear(); levels.clear(); waves.clear(); backgrounds.clear(); _level_errors.clear()
	_appearances.clear()
	_skill_icons.clear()
	starting_operators.clear(); recruits.clear(); departures.clear(); returns.clear()
	_load_actors(data_base + "/actors.tres")
	for row in _table(base + "/backgrounds.csv", "id,texture"):
		_resource(row, "texture")
		backgrounds[row.id] = row.texture
	for row in _table(base + "/levels.csv", "id,name,description,map,life,initial_cost,cost_cap,cost_regen,deploy_limit,defend_duration,before,after"):
		var level := {"id": row.id, "name": row.name, "description": row.description, "map": row.map,
			"before": row.before, "after": row.after, "enemies": {}, "waves": [], "route_warning_duration": 2.0}
		for field in ["life", "deploy_limit"]: level[field] = int(_number(row, field, 1, true))
		for field in ["initial_cost", "cost_cap", "cost_regen", "defend_duration"]: level[field] = _number(row, field, 0)
		if level.initial_cost > level.cost_cap: _error(row, "initial_cost", "不能大于 cost_cap")
		_resource(row, "map")
		levels[row.id] = level
		_level_errors[row.id] = PackedStringArray()
		for field in ["before", "after"]:
			if field == "after" and row[field].is_empty(): continue
			var start := errors.size()
			story(row[field])
			for index in range(start, errors.size()): _level_errors[row.id].append(errors[index])
			errors.resize(start)
	for row in _table(base + "/player_roster.csv", "id,join_after,leave_after,return_after"):
		if not characters.has(row.id):
			_error(row, "id", "未知干员 " + row.id); continue
		if row.join_after.is_empty(): starting_operators.append(row.id)
		for entry in [["join_after", recruits], ["leave_after", departures], ["return_after", returns]]:
			var field: String = entry[0]
			var events: Dictionary = entry[1]
			if row[field].is_empty(): continue
			if not levels.has(row[field]): _error(row, field, "未知剧情完成时点 " + row[field])
			else:
				if not events.has(row[field]): events[row[field]] = []
				events[row[field]].append(row.id)
	if starting_operators.is_empty(): errors.append(base + "/player_roster.csv:1 [id] 初始干员不能为空")
	for row in _table(base + "/waves.csv", "id,level,time,count,interval,enemy,route,number"):
		var wave := {"time": _number(row, "time", 0), "count": int(_number(row, "count", 1, true)),
			"interval": _number(row, "interval", 0.000001), "enemy": row.enemy, "route": row.route, "number": int(_number(row, "number", 1, true))}
		if not levels.has(row.level): _error(row, "level", "未知关卡 " + row.level)
		elif not enemies.has(row.enemy): _error(row, "enemy", "未知敌人 " + row.enemy)
		else:
			levels[row.level].waves.append(wave)
			levels[row.level].enemies[row.enemy] = enemies[row.enemy].stats.duplicate(true)
		waves.append(row)
	for id in levels:
		if levels[id].waves.is_empty(): _level_errors[id].append("%s/levels.csv:1 [waves] %s 没有波次" % [base, id])
	return errors.duplicate()

func _load_actors(path: String) -> void:
	if not ResourceLoader.exists(path):
		errors.append(path + " [library] 资源不存在"); return
	# Ignore dependencies too: saved stat, skill and appearance edits must reload.
	var library = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE_DEEP)
	if not library is Library:
		errors.append(path + " [library] 必须为 ActorLibrary"); return
	for skill in library.skills:
		if skill == null:
			errors.append(path + " [skills] 技能资源为空"); continue
		if not _accept_id(skill.content_id, "skill", skill.resource_path, skills): continue
		for message in skill.errors(): errors.append(skill.resource_path + " [skill] " + message)
		skills[skill.content_id] = skill.configuration()
	var skill_paths := {}
	for skill in library.skills:
		if skill: skill_paths[skill.content_id] = skill.resource_path
	for actor in library.characters: _register_actor(actor, false, path, skill_paths)
	for actor in library.enemies: _register_actor(actor, true, path, skill_paths)
	if characters.is_empty() or enemies.is_empty() or skills.is_empty():
		errors.append(path + " [library] 角色、敌人和技能不能为空")

func _accept_id(id: String, prefix: String, path: String, collection: Dictionary) -> bool:
	if path.is_empty() or path.contains("::"):
		errors.append(path + " [resource] 必须保存为独立资源"); return false
	var pattern := RegEx.new()
	pattern.compile("^%s_[0-9]{3,}$" % prefix)
	if pattern.search(id) == null or collection.has(id):
		errors.append(path + " [content_id] ID 格式错误或重复: " + id); return false
	return true

func _register_actor(actor, enemy: bool, path: String, skill_paths: Dictionary) -> void:
	if actor == null:
		errors.append(path + " [actors] 角色定义为空"); return
	path = actor.resource_path
	if actor.stats == null:
		errors.append(path + " [stats] 数值资源为空"); return
	var stats = actor.stats
	var collection: Dictionary = enemies if enemy else characters
	if not _accept_id(stats.content_id, "enemy" if enemy else "character", path, collection): return
	for message in stats.errors(): errors.append(stats.resource_path + " [stats] " + message)
	if not enemy:
		var skill = stats.skill_spec
		if skill == null or not skills.has(skill.content_id) or skill_paths.get(skill.content_id) != skill.resource_path:
			errors.append(stats.resource_path + " [skill_spec] 必须引用 actors.tres 中注册的独立技能资源")
		elif skill.get("icon") != null:
			_skill_icons[stats.content_id] = skill.icon
	var appearance = actor.appearance
	if appearance == null or appearance.poses.size() != 4 or appearance.poses.has(null) or appearance.portrait == null:
		errors.append(path + " [appearance] 外观需要四种姿态及头像"); return
	if not appearance.resource_path.begins_with("res://content/") and not appearance.resource_path.begins_with(path + "::"):
		errors.append(path + " [appearance] 必须引用正式 content 资源")
	var config: Dictionary = stats.configuration(enemy)
	config.content_id = stats.content_id
	collection[stats.content_id] = {"stats": config, "appearance": appearance.resource_path,
		"identity": actor.identity, "class": actor.profession}
	_appearances[stats.content_id] = appearance

func diagnostics(id: String) -> PackedStringArray:
	var result := errors.duplicate()
	result.append_array(_level_errors.get(id, PackedStringArray()))
	if not levels.has(id): result.append("levels.csv:1 [id] 未知关卡 " + id)
	return result

func battle_operator_ids(id: String, operator_ids: Array = []) -> Array:
	if id == "scene_002": return ["character_011", "character_012"]
	return starting_operators.duplicate() if operator_ids.is_empty() else operator_ids.duplicate()

func configuration(id: String, map: Node, operator_ids: Array = []) -> Dictionary:
	var result: Dictionary = levels[id].duplicate(true)
	result.roster = operator_configuration(battle_operator_ids(id, operator_ids))
	result.terrain = {}
	var cells: Dictionary = map.cells()
	for cell in cells:
		var data: Dictionary = cells[cell]
		if data.deployment in ["ground", "high"]: result.terrain[cell] = data.deployment
	result.routes = map.routes()
	return result

func map_errors(id: String, map: Node) -> PackedStringArray:
	var result := diagnostics(id)
	for message in map.errors(false): result.append("%s:1 [geometry] %s" % [levels[id].map, message])
	for row in waves:
		if row.level == id and not map.routes().has(row.route):
			result.append("%s:%s [route] 未知路线 %s" % [row._file, row._line, row.route])
	return result

func operator_configuration(operator_ids: Array) -> Dictionary:
	var result := {}
	var ordered := operator_ids.duplicate()
	ordered.sort_custom(func(a, b): return str(a).naturalnocasecmp_to(str(b)) < 0)
	for key in ordered: result[key] = characters[key].stats.duplicate(true)
	return result

func operator_errors(operator_ids: Array) -> PackedStringArray:
	var result := PackedStringArray()
	if operator_ids.is_empty(): result.append("Player: 干员列表不能为空")
	for key in operator_ids:
		if not characters.has(key): result.append("Player: 未知干员 " + str(key))
	if operator_ids.size() != _unique_count(PackedStringArray(operator_ids)): result.append("Player: 干员列表存在重复 ID")
	return result

func appearances(id: String, operator_ids: Array = []) -> Dictionary:
	var result := {}
	for key in battle_operator_ids(id, operator_ids): result[key] = _appearances[key]
	for key in levels[id].enemies: result[key] = _appearances[key]
	return result

func story_textures() -> Dictionary:
	var result := {"backgrounds": {}, "actors": {}}
	for id in backgrounds: result.backgrounds[id] = load(backgrounds[id])
	for id in _appearances: result.actors[id] = _appearances[id].poses[0]
	return result

func skill_icons(id: String, operator_ids: Array = []) -> Dictionary:
	var result := {}
	for key in battle_operator_ids(id, operator_ids):
		if _skill_icons.has(key): result[key] = _skill_icons[key]
	return result

func story(path: String) -> Resource:
	var script = StoryScript.new()
	script.title = path.get_file().get_basename()
	script.start = "line_0"
	if not FileAccess.file_exists(path):
		errors.append(path + ":1 [file] 剧情文件不存在")
		return script
	var lines := FileAccess.get_file_as_string(path).replace("\r", "").split("\n")
	var node := {}
	var index := 0
	var at := 1
	for offset in lines.size():
		var line: String = lines[offset]
		if line.begins_with("# "):
			script.title = line.substr(2)
		elif line == "---":
			if not node.is_empty():
				_add_line(script, node, index, path, at)
				index += 1
			node = {"type": "line", "text": "", "actors": []}; at = offset + 1
		elif not node.is_empty():
			if line.begins_with("background: "): node.background = line.substr(12).strip_edges()
			elif line.begins_with("framing: "): node.framing = line.substr(9).strip_edges()
			elif line.begins_with("screen_shake: "):
				var value := line.substr(14).strip_edges()
				if value not in ["true", "false"]: errors.append("%s:%d [screen_shake] 必须为 true 或 false" % [path, offset + 1])
				node.screen_shake = value == "true"
			elif line.begins_with("actor_shake:"): node.actor_shake = Array(line.substr(12).strip_edges().split("|", false))
			elif line.begins_with("actor_flip:"): node.actor_flip = Array(line.substr(11).strip_edges().split("|", false))
			elif line.begins_with("actor_mirrored:"): node.actor_mirrored = Array(line.substr(15).strip_edges().split("|", false))
			elif line.begins_with("actor_exit_left:"): node.actor_exit_left = Array(line.substr(16).strip_edges().split("|", false))
			elif line.begins_with("actor_exit_right:"): node.actor_exit_right = Array(line.substr(17).strip_edges().split("|", false))
			elif line.begins_with("actors:"): node.actors = Array(line.substr(7).strip_edges().split("|", false))
			elif line.begins_with("speaker: "): node.speaker_actor = line.substr(9).strip_edges()
			elif line.begins_with("> "): node.text += ("\n" if not node.text.is_empty() else "") + line.substr(2)
			elif not line.strip_edges().is_empty(): errors.append("%s:%d [syntax] 未知剧情标记" % [path, offset + 1])
	if not node.is_empty():
		_add_line(script, node, index, path, at); index += 1
	script.nodes["line_%d" % index] = {"type": "end", "text": "", "actors": []}
	if index == 0: errors.append(path + ":1 [text] 剧情不能为空")
	return script

func _add_line(script: Resource, node: Dictionary, index: int, path: String, at: int) -> void:
	if node.get("framing", "wide") not in ["wide", "left_close"]: errors.append("%s:%d [framing] 未知背景取景" % [path, at])
	if node.text.is_empty(): errors.append("%s:%d [text] 对白不能为空" % [path, at])
	if not backgrounds.has(node.get("background", "")): errors.append("%s:%d [background] 未知背景" % [path, at])
	if node.actors.size() > 2 or (node.actors.size() == 2 and node.actors[0] == node.actors[1]): errors.append("%s:%d [actors] 最多两名不重复角色" % [path, at])
	for actor in node.actors:
		if not characters.has(actor) and not enemies.has(actor): errors.append("%s:%d [actors] 未知角色 %s" % [path, at, actor])
	for field in ["actor_shake", "actor_flip", "actor_mirrored", "actor_exit_left", "actor_exit_right"]:
		for actor in node.get(field, []):
			if not node.actors.has(actor): errors.append("%s:%d [%s] 效果目标必须出场 %s" % [path, at, field, actor])
		if node.get(field, []).size() != _unique_count(PackedStringArray(node.get(field, []))):
			errors.append("%s:%d [%s] 效果目标不能重复" % [path, at, field])
	for actor in node.get("actor_exit_left", []):
		if node.get("actor_exit_right", []).has(actor): errors.append("%s:%d [actor_exit_left/actor_exit_right] 同一角色不能同时向两侧离场 %s" % [path, at, actor])
	var speaker: String = node.get("speaker_actor", "")
	if speaker != "narrator" and not node.actors.has(speaker): errors.append("%s:%d [speaker] 说话人必须出场" % [path, at])
	node.speaker = characters[speaker].stats.name if characters.has(speaker) else (enemies[speaker].stats.name if enemies.has(speaker) else "旁白")
	node.speaker_actor = "" if speaker == "narrator" else speaker
	node.next = "line_%d" % (index + 1)
	script.nodes["line_%d" % index] = node.duplicate(true)

func _table(path: String, columns: String) -> Array:
	var result: Array = []
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		errors.append(path + ":1 [file] 无法读取 CSV"); return result
	var header := file.get_csv_line()
	if not header.is_empty(): header[0] = header[0].trim_prefix("\uFEFF")
	var valid := true
	for field in columns.split(","):
		if not header.has(field):
			errors.append("%s:1 [%s] 缺少列" % [path, field]); valid = false
	if header.size() != columns.split(",").size() or header.size() != _unique_count(header):
		errors.append(path + ":1 [header] 列数错误或列名重复"); valid = false
	if not valid: return result
	var ids := {}
	var id_pattern := RegEx.new()
	id_pattern.compile("^[a-z]+_[0-9]{3,}$")
	var line := 2
	while file.get_position() < file.get_length():
		var position := file.get_position()
		var fields := file.get_csv_line()
		var end := file.get_position()
		file.seek(position)
		var raw := file.get_buffer(end - position).get_string_from_utf8()
		file.seek(end)
		var at := line
		line += raw.count("\n")
		if fields.size() == 1 and fields[0].strip_edges().is_empty(): continue
		if fields.size() != header.size():
			errors.append("%s:%d [row] 列数不匹配" % [path, at]); continue
		var row := {"_file": path, "_line": at}
		for i in header.size(): row[header[i]] = fields[i].strip_edges()
		if row.id.is_empty() or ids.has(row.id):
			_error(row, "id", "ID 为空或重复"); continue
		if id_pattern.search(row.id) == null:
			_error(row, "id", "使用 type_001 格式"); continue
		ids[row.id] = true
		result.append(row)
	return result

func _unique_count(values: PackedStringArray) -> int:
	var seen := {}
	for value in values: seen[value] = true
	return seen.size()

func _number(row: Dictionary, field: String, minimum: float, integer := false) -> float:
	var value: String = row[field]
	if not value.is_valid_float() or not is_finite(value.to_float()) or value.to_float() < minimum or (integer and not value.is_valid_int()):
		_error(row, field, "必须为%s且不小于 %s" % ["整数" if integer else "有限数值", minimum]); return minimum
	return value.to_float()

func _resource(row: Dictionary, field: String) -> void:
	var path: String = row[field]
	if not path.begins_with("res://content/") or not ResourceLoader.exists(path):
		_error(row, field, "正式资源不存在 " + path); return
	var resource = load(path)
	if field == "map":
		if not resource is PackedScene: _error(row, field, "必须为地图场景")
		else:
			var map = resource.instantiate()
			if not map.has_method("cells") or not map.has_method("errors") or not map.has_method("routes") or not map.get_node_or_null("Terrain") is TileMapLayer or map.get_node_or_null("Routes") == null:
				_error(row, field, "需要 EditableMap、Terrain 和 Routes")
			map.free()
	elif field == "texture" and not resource is Texture2D: _error(row, field, "必须为贴图")

func _error(row: Dictionary, field: String, message: String) -> void:
	errors.append("%s:%s [%s] %s" % [row._file, row._line, field, message])
