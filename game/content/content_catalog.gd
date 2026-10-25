extends RefCounted
## Source files are authoritative. Builds battle dictionaries and StoryScript resources.
const StoryScript = preload("res://features/story/story_script.gd")
const ROOT := "res://content/campaign"
var errors := PackedStringArray()
var characters := {}
var skills := {}
var enemies := {}
var levels := {}
var waves: Array = []
var backgrounds := {}
var _level_errors := {}

func reload(base := ROOT) -> PackedStringArray:
	errors.clear(); characters.clear(); skills.clear(); enemies.clear(); levels.clear(); waves.clear(); backgrounds.clear(); _level_errors.clear()
	for row in _table(base + "/skills.csv", "id,name,description,recovery,required,initial_sp,duration,multiplier,interval_multiplier,cost_gain"):
		var skill := {"enabled": true, "name": row.name, "description": row.description, "recovery": row.recovery}
		for field in ["required", "duration", "multiplier", "interval_multiplier"]: skill[field] = _number(row, field, 0.000001)
		for field in ["initial_sp", "cost_gain"]: skill[field] = _number(row, field, 0)
		_enum(row, "recovery", ["auto", "attack", "hit"])
		if skill.initial_sp > skill.required: _error(row, "initial_sp", "不能大于 required")
		skills[row.id] = skill
	for row in _table(base + "/characters.csv", "id,name,identity,class,appearance,role,max_hp,attack,defense,resistance,interval,windup,cost,redeploy_time,block,range,skill"):
		var unit := _actor(row)
		unit.merge({"name": row.name, "content_id": row.id, "role": row.role, "cost": _number(row, "cost", 0),
			"redeploy_time": _number(row, "redeploy_time", 0), "block": int(_number(row, "block", 0, true)),
			"range": _range(row), "anti_air": row.role == "ranged", "skill": skills.get(row.skill, {})})
		_enum(row, "role", ["melee", "ranged", "healer"])
		if not skills.has(row.skill): _error(row, "skill", "未知技能 " + row.skill)
		_resource(row, "appearance")
		characters[row.id] = {"stats": unit, "appearance": row.appearance, "identity": row.identity, "class": row["class"]}
	for row in _table(base + "/enemies.csv", "id,name,appearance,max_hp,attack,defense,resistance,interval,windup,speed,ranged,range,leak_damage"):
		var enemy := _actor(row)
		enemy.merge({"name": row.name, "content_id": row.id, "speed": _number(row, "speed", 0), "ranged": row.ranged == "true",
			"range": _number(row, "range", 0), "leak_damage": int(_number(row, "leak_damage", 1, true))})
		_enum(row, "ranged", ["true", "false"])
		_resource(row, "appearance")
		enemies[row.id] = {"stats": enemy, "appearance": row.appearance}
	for row in _table(base + "/backgrounds.csv", "id,texture"):
		_resource(row, "texture")
		backgrounds[row.id] = row.texture
	for row in _table(base + "/levels.csv", "id,name,description,map,roster,life,initial_cost,cost_cap,cost_regen,deploy_limit,defend_duration,before,after"):
		var level := {"id": row.id, "name": row.name, "description": row.description, "map": row.map,
			"before": row.before, "after": row.after, "roster": {}, "enemies": {}, "waves": [], "route_warning_duration": 2.0}
		for field in ["life", "deploy_limit"]: level[field] = int(_number(row, field, 1, true))
		for field in ["initial_cost", "cost_cap", "cost_regen", "defend_duration"]: level[field] = _number(row, field, 0)
		if level.initial_cost > level.cost_cap: _error(row, "initial_cost", "不能大于 cost_cap")
		for id in row.roster.split("|", false):
			if not characters.has(id): _error(row, "roster", "未知角色 " + id)
			elif level.roster.has(id): _error(row, "roster", "重复角色 " + id)
			else: level.roster[id] = characters[id].stats.duplicate(true)
		if level.roster.is_empty(): _error(row, "roster", "至少一个角色")
		_resource(row, "map")
		levels[row.id] = level
		_level_errors[row.id] = PackedStringArray()
		for field in ["before", "after"]:
			var start := errors.size()
			story(row[field])
			for index in range(start, errors.size()): _level_errors[row.id].append(errors[index])
			errors.resize(start)
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

func diagnostics(id: String) -> PackedStringArray:
	var result := errors.duplicate()
	result.append_array(_level_errors.get(id, PackedStringArray()))
	if not levels.has(id): result.append("levels.csv:1 [id] 未知关卡 " + id)
	return result

func configuration(id: String, map: Node) -> Dictionary:
	var result: Dictionary = levels[id].duplicate(true)
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

func appearances(id: String) -> Dictionary:
	var result := {}
	for key in levels[id].roster: result[key] = load(characters[key].appearance)
	for key in levels[id].enemies: result[key] = load(enemies[key].appearance)
	return result

func story_textures() -> Dictionary:
	var result := {"backgrounds": {}, "actors": {}}
	for id in backgrounds: result.backgrounds[id] = load(backgrounds[id])
	for id in characters: result.actors[id] = load(characters[id].appearance).poses[0]
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
	if node.text.is_empty(): errors.append("%s:%d [text] 对白不能为空" % [path, at])
	if not backgrounds.has(node.get("background", "")): errors.append("%s:%d [background] 未知背景" % [path, at])
	if node.actors.size() > 2 or (node.actors.size() == 2 and node.actors[0] == node.actors[1]): errors.append("%s:%d [actors] 最多两名不重复角色" % [path, at])
	for actor in node.actors:
		if not characters.has(actor): errors.append("%s:%d [actors] 未知角色 %s" % [path, at, actor])
	var speaker: String = node.get("speaker_actor", "")
	if speaker != "narrator" and not node.actors.has(speaker): errors.append("%s:%d [speaker] 说话人必须出场" % [path, at])
	node.speaker = characters[speaker].stats.name if characters.has(speaker) else "旁白"
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

func _actor(row: Dictionary) -> Dictionary:
	var result := {"damage_type": "physical"}
	for field in ["max_hp", "interval"]: result[field] = _number(row, field, 0.000001)
	for field in ["attack", "defense", "resistance", "windup"]: result[field] = _number(row, field, 0)
	if result.resistance > 95: _error(row, "resistance", "必须在 0 至 95 之间")
	if result.windup > result.interval: _error(row, "windup", "不能大于 interval")
	return result

func _range(row: Dictionary) -> Array:
	var result: Array = []
	for cell in row.range.split("|", false):
		var xy: PackedStringArray = cell.split(":")
		if xy.size() != 2 or not xy[0].is_valid_int() or not xy[1].is_valid_int(): _error(row, "range", "使用 x:y|x:y 格式")
		else: result.append(Vector2i(int(xy[0]), int(xy[1])))
	if result.is_empty(): _error(row, "range", "攻击范围不能为空")
	return result

func _number(row: Dictionary, field: String, minimum: float, integer := false) -> float:
	var value: String = row[field]
	if not value.is_valid_float() or not is_finite(value.to_float()) or value.to_float() < minimum or (integer and not value.is_valid_int()):
		_error(row, field, "必须为%s且不小于 %s" % ["整数" if integer else "有限数值", minimum]); return minimum
	return value.to_float()

func _enum(row: Dictionary, field: String, allowed: Array) -> void:
	if not row[field] in allowed: _error(row, field, "可用值 " + "/".join(allowed))

func _resource(row: Dictionary, field: String) -> void:
	var path: String = row[field]
	if not path.begins_with("res://content/") or not ResourceLoader.exists(path):
		_error(row, field, "正式资源不存在 " + path); return
	var resource = load(path)
	if field == "appearance":
		if resource == null or resource.get("poses") == null or resource.poses.size() != 4 or resource.get("portrait") == null:
			_error(row, field, "外观需要四种姿态及头像")
	elif field == "map":
		if not resource is PackedScene: _error(row, field, "必须为地图场景")
		else:
			var map = resource.instantiate()
			if not map.has_method("cells") or not map.has_method("errors") or not map.has_method("routes") or not map.get_node_or_null("Terrain") is TileMapLayer or map.get_node_or_null("Routes") == null:
				_error(row, field, "需要 EditableMap、Terrain 和 Routes")
			map.free()
	elif field == "texture" and not resource is Texture2D: _error(row, field, "必须为贴图")

func _error(row: Dictionary, field: String, message: String) -> void:
	errors.append("%s:%s [%s] %s" % [row._file, row._line, field, message])
