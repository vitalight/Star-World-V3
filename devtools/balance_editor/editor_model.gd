@tool
extends RefCounted
const Csv = preload("res://devtools/balance_editor/csv_document.gd")
const SafeWrite = preload("res://devtools/balance_editor/safe_write.gd")
var data_dir := "res://content/data/"
var campaign_dir := "res://content/campaign/"
var levels = Csv.new()
var waves = Csv.new()
var library: Resource
var actors := {}
var skills := {}
var snapshots := {}
var modified := {}
var table_dirty := false
var errors := PackedStringArray()

func load_all() -> bool:
	errors.clear()
	actors.clear()
	skills.clear()
	snapshots.clear()
	snapshots[data_dir + "actors.tres"] = FileAccess.get_file_as_bytes(data_dir + "actors.tres")
	modified.clear()
	table_dirty = false
	if not levels.load_table(campaign_dir + "levels.csv"):
		errors.append(levels.error)
	if not waves.load_table(campaign_dir + "waves.csv"):
		errors.append(waves.error)
	library = ResourceLoader.load(data_dir + "actors.tres", "", ResourceLoader.CACHE_MODE_IGNORE_DEEP)
	if library == null:
		errors.append("无法读取角色、怪物与技能注册表")
		return false
	for group in [library.characters, library.enemies]:
		for entry in group:
			if entry == null or entry.stats == null:
				errors.append("单位注册表包含空项")
				continue
			var path: String = entry.resource_path
			var draft = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE_DEEP)
			if draft == null:
				errors.append("无法读取 " + path)
				continue
			actors[draft.stats.content_id] = draft
			snapshots[path] = FileAccess.get_file_as_bytes(path)
	for entry in library.skills:
		if entry == null:
			errors.append("技能注册表包含空项")
			continue
		var path: String = entry.resource_path
		var draft = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE_DEEP)
		if draft == null:
			errors.append("无法读取 " + path)
			continue
		skills[draft.content_id] = draft
		snapshots[path] = FileAccess.get_file_as_bytes(path)
	return errors.is_empty()

func mark_resource(path: String) -> void:
	modified[path] = true

func has_changes() -> bool:
	return table_dirty or not modified.is_empty()

func validate() -> PackedStringArray:
	var result := PackedStringArray()
	var battle_levels := {}
	for row in levels.rows:
		var v: Dictionary = row.values
		if v.type != "battle":
			continue
		battle_levels[v.id] = v
		for field in ["life", "deploy_limit"]:
			if not str(v[field]).is_valid_int() or int(v[field]) < 1:
				result.append("%s：%s 必须是正整数" % [v.id, field])
		for field in ["initial_cost", "cost_cap", "cost_regen", "defend_duration"]:
			var value := str(v[field])
			if not value.is_valid_float() or not is_finite(value.to_float()) or value.to_float() < 0:
				result.append("%s：%s 必须是非负数" % [v.id, field])
		if float(v.initial_cost) > float(v.cost_cap):
			result.append("%s：初始费用不能超过费用上限" % v.id)
		if v.roster_mode not in ["fixed", "player"]:
			result.append("%s：编队模式必须是 fixed 或 player" % v.id)
		var roster: PackedStringArray = str(v.fixed_roster).split("|", false)
		if v.roster_mode == "fixed" and roster.is_empty():
			result.append("%s：固定编队不能为空" % v.id)
		if v.roster_mode == "player" and not roster.is_empty():
			result.append("%s：玩家编队不能填写固定编队" % v.id)
		var unique := {}
		for id in roster:
			if unique.has(id) or not actors.has(id) or not id.begins_with("character_"):
				result.append("%s：干员不存在或重复：%s" % [v.id, id])
			unique[id] = true
	var route_data := {}
	for id in battle_levels:
		var map_path: String = battle_levels[id].map
		var scene = ResourceLoader.load(map_path, "", ResourceLoader.CACHE_MODE_IGNORE_DEEP)
		if not scene is PackedScene:
			result.append("%s：地图不可读取" % id)
			continue
		var map = scene.instantiate()
		if map == null or not map.has_method("routes") or not map.has_method("errors"):
			result.append("%s：地图格式错误" % id)
			if map: map.free()
			continue
		route_data[id] = {"routes": map.routes(), "air": map.flying_routes()}
		for message in map.errors(false):
			result.append("%s：%s" % [id, message])
		map.free()
	var ids := {}
	var counts := {}
	for row in waves.rows:
		var v: Dictionary = row.values
		var id := str(v.id)
		if ids.has(id) or not id.begins_with("wave_") or not id.trim_prefix("wave_").is_valid_int():
			result.append("波次 ID 无效或重复：" + id)
		ids[id] = true
		if not battle_levels.has(v.level):
			result.append("%s：关卡不存在" % id)
			continue
		counts[v.level] = int(counts.get(v.level, 0)) + 1
		for field in ["count", "number"]:
			if not str(v[field]).is_valid_int() or int(v[field]) < 1:
				result.append("%s：%s 必须是正整数" % [id, field])
		for field in ["time", "interval"]:
			var value := str(v[field])
			if not value.is_valid_float() or not is_finite(value.to_float()) or value.to_float() < 0 or (field == "interval" and value.to_float() <= 0):
				result.append("%s：%s 数值无效" % [id, field])
		if not actors.has(v.enemy) or not str(v.enemy).begins_with("enemy_"):
			result.append("%s：敌人不存在：%s" % [id, v.enemy])
		elif route_data.has(v.level):
			var info: Dictionary = route_data[v.level]
			if not info.routes.has(v.route):
				result.append("%s：路线不存在：%s" % [id, v.route])
			elif info.air.has(v.route) and not actors[v.enemy].stats.flying:
				result.append("%s：地面敌人不能使用飞行路线" % id)
	for id in battle_levels:
		if not counts.has(id): result.append("%s：至少需要一个波次" % id)
	for id in actors:
		for message in actors[id].stats.errors():
			result.append("%s：%s" % [id, message])
	for id in skills:
		for message in skills[id].errors():
			result.append("%s：%s" % [id, message])
	return result

func save_all() -> PackedStringArray:
	var result := validate()
	if not result.is_empty(): return result
	if FileAccess.get_file_as_bytes(data_dir + "actors.tres") != snapshots[data_dir + "actors.tres"]:
		return PackedStringArray(["资源注册表已被外部修改，草稿未保存。"])
	if table_dirty and (levels.conflicts() or waves.conflicts()):
		return PackedStringArray(["关卡或波次源文件已被外部修改，草稿未保存。"])
	for path in modified:
		if not FileAccess.file_exists(path) or FileAccess.get_file_as_bytes(path) != snapshots[path]:
			return PackedStringArray(["资源已被外部修改：" + path])
	var replacements := {}
	if table_dirty:
		replacements[levels.path] = levels.serialize().to_utf8_buffer()
		replacements[waves.path] = waves.serialize().to_utf8_buffer()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://temp/balance_editor"))
	for path in modified:
		var resource: Resource = null
		for actor in actors.values():
			if actor.resource_path == path: resource = actor
		for skill in skills.values():
			if skill.resource_path == path: resource = skill
		if resource == null: return PackedStringArray(["资源丢失：" + path])
		var staged: String = "res://temp/balance_editor/" + path.get_file()
		var code := ResourceSaver.save(resource, staged)
		if code != OK: return PackedStringArray(["无法暂存 %s：%s" % [path, error_string(code)]])
		replacements[path] = FileAccess.get_file_as_bytes(staged)
	var originals := {}
	for path in replacements:
		originals[path] = levels.original_bytes if path == levels.path else (waves.original_bytes if path == waves.path else snapshots[path])
	var written := []
	for path in replacements:
		var failure := ""
		if not FileAccess.file_exists(path) or FileAccess.get_file_as_bytes(path) != originals[path]:
			failure = "保存期间文件被外部修改：" + path
		else:
			failure = SafeWrite.replace(path, replacements[path])
		if not failure.is_empty():
			result.append(failure)
			for previous in written:
				var rollback: String = SafeWrite.replace(previous, originals[previous])
				if not rollback.is_empty(): result.append("恢复失败：" + rollback)
			return result
		written.append(path)
	if not load_all():
		result.append_array(errors)
	return result
