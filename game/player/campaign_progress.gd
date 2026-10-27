extends RefCounted
## Versioned chapter progress. Existing legacy sections survive writes.
var selected := "scene_0101A"
var completed: Array[String] = []
var pending_after := ""
var started := false
var operators: Array[String] = []
var away_operators: Array[String] = []
var _has_roster_state := false
var _file := ConfigFile.new()

func load_progress(path: String, ids: Array) -> void:
	_file = ConfigFile.new()
	selected = str(ids[0]) if not ids.is_empty() else ""
	completed.clear(); pending_after = ""; started = false
	operators.clear()
	away_operators.clear(); _has_roster_state = false
	if _file.load(path) != OK: return
	if _file.get_value("campaign", "version", 0) not in [1, 2, 3]: return
	var saved_operators = _file.get_value("player", "operators", [])
	if saved_operators is Array:
		_has_roster_state = _file.get_value("campaign", "version", 0) >= 2 and not saved_operators.is_empty()
		for id in saved_operators:
			if id is String and not operators.has(id): operators.append(id)
	var saved_away = _file.get_value("player", "away", [])
	if saved_away is Array:
		for id in saved_away:
			if id is String and operators.has(id) and not away_operators.has(id): away_operators.append(id)
	var saved = _file.get_value("campaign", "completed", [])
	var selection = _file.get_value("campaign", "selected", selected)
	var pending = _file.get_value("campaign", "pending_after", "")
	if _file.get_value("campaign", "version", 0) < 3 and ids.has("scene_0101A"):
		var old_ids := ["scene_002", "scene_005", "scene_003", "scene_004"]
		if saved is not Array: saved = []
		else: saved = saved.duplicate()
		if (saved.has("scene_003") or pending == "scene_003") and not saved.has("scene_005"): saved.append("scene_005")
		var migrated: Array = []
		for i in old_ids.size():
			var story_id: String = "scene_01%02dA" % (i + 1)
			var battle_id: String = "scene_01%02dB" % (i + 1)
			if saved.has(old_ids[i]):
				migrated.append(story_id); migrated.append(battle_id)
			elif pending == old_ids[i]:
				migrated.append(story_id)
				pending = battle_id
				break
			else: break
		if saved.has("scene_004"): migrated.append("scene_0105A")
		var pending_index := old_ids.find(pending)
		if pending_index >= 0: pending = "scene_01%02dB" % (pending_index + 1)
		saved = migrated
		# Old selection named the combined level; resume at its story unless that
		# level was already completed, in which case retain a selectable entry.
		var old_index := old_ids.find(selection)
		if old_index >= 0: selection = "scene_01%02dA" % (old_index + 1)
	if saved is Array:
		for id in ids:
			if not saved.has(id): break
			completed.append(id)
	if selection is String and ids.has(selection) and unlocked(selection, ids): selected = selection
	elif completed.size() < ids.size(): selected = ids[completed.size()]
	if pending is String and ids.has(pending) and unlocked(pending, ids):
		pending_after = pending
		selected = pending
	started = _file.get_value("campaign", "started", false) == true

func configure_operators(initial: Array, recruitment: Dictionary, valid_ids: Array, departures: Dictionary = {}, returns: Dictionary = {}) -> void:
	operators.assign(operators.filter(func(id): return valid_ids.has(id)))
	away_operators.assign(away_operators.filter(func(id): return operators.has(id)))
	for id in initial:
		if not operators.has(id): operators.append(id)
	# Also migrates old progress-only saves without losing earned operators.
	for level in completed:
		_recruit(recruitment.get(level, []))
		if not _has_roster_state: _apply_availability(level, departures, returns)
	operators.sort_custom(func(a, b): return a.naturalnocasecmp_to(b) < 0)
	_has_roster_state = true

func available_operators() -> Array[String]:
	var result: Array[String] = []
	for id in operators:
		if not away_operators.has(id): result.append(id)
	return result

func _apply_availability(level: String, departures: Dictionary, returns: Dictionary) -> void:
	for id in departures.get(level, []):
		if operators.has(id) and not away_operators.has(id): away_operators.append(id)
	for id in returns.get(level, []): away_operators.erase(id)

func _recruit(ids: Array) -> void:
	for id in ids:
		if not operators.has(id): operators.append(id)
	operators.sort_custom(func(a, b): return a.naturalnocasecmp_to(b) < 0)

func unlocked(id: String, ids: Array) -> bool:
	var index := ids.find(id)
	return index >= 0 and (index == 0 or completed.has(ids[index - 1]))

func save(path: String) -> Error:
	_file.set_value("campaign", "version", 3)
	_file.set_value("player", "operators", operators)
	_file.set_value("player", "away", away_operators)
	_file.set_value("campaign", "selected", selected)
	_file.set_value("campaign", "completed", completed)
	_file.set_value("campaign", "pending_after", pending_after)
	_file.set_value("campaign", "started", started)
	return _file.save(path)

func finish_story(ids: Array, recruitment: Dictionary = {}, departures: Dictionary = {}, returns: Dictionary = {}) -> void:
	if not pending_after.is_empty():
		if not completed.has(pending_after):
			_recruit(recruitment.get(pending_after, []))
			_apply_availability(pending_after, departures, returns)
			completed.append(pending_after)
		var next := ids.find(pending_after) + 1
		if next < ids.size(): selected = ids[next]
		pending_after = ""
