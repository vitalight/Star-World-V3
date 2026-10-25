extends RefCounted
## Versioned chapter progress. Existing legacy sections survive writes.
var selected := "scene_002"
var completed: Array[String] = []
var pending_after := ""
var started := false
var _file := ConfigFile.new()

func load_progress(path: String, ids: Array) -> void:
	_file = ConfigFile.new()
	selected = str(ids[0]) if not ids.is_empty() else ""
	completed.clear(); pending_after = ""; started = false
	if _file.load(path) != OK: return
	if _file.get_value("campaign", "version", 0) != 1: return
	var saved = _file.get_value("campaign", "completed", [])
	if saved is Array:
		# Only accept a sequential prefix: a malformed save cannot skip chapters.
		for id in ids:
			if not saved.has(id): break
			completed.append(id)
	var selection = _file.get_value("campaign", "selected", selected)
	if selection is String and ids.has(selection) and unlocked(selection, ids): selected = selection
	var pending = _file.get_value("campaign", "pending_after", "")
	if pending is String and ids.has(pending) and unlocked(pending, ids): pending_after = pending
	started = _file.get_value("campaign", "started", false) == true

func unlocked(id: String, ids: Array) -> bool:
	var index := ids.find(id)
	return index >= 0 and (index == 0 or completed.has(ids[index - 1]))

func save(path: String) -> Error:
	_file.set_value("campaign", "version", 1)
	_file.set_value("campaign", "selected", selected)
	_file.set_value("campaign", "completed", completed)
	_file.set_value("campaign", "pending_after", pending_after)
	_file.set_value("campaign", "started", started)
	return _file.save(path)

func finish_story(ids: Array) -> void:
	if not pending_after.is_empty():
		if not completed.has(pending_after): completed.append(pending_after)
		var next := ids.find(pending_after) + 1
		if next < ids.size(): selected = ids[next]
		pending_after = ""
