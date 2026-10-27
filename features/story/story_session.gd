extends RefCounted
## Synchronous dialogue progression; UI, assets, and game flow stay with the caller.
const ScriptData = preload("res://features/story/story_script.gd")
var _nodes: Dictionary = {}
var _title: String = ""
var _start: String = ""
var _current: String = ""
var _history: Array[Dictionary] = []

func load_story(story: ScriptData) -> PackedStringArray:
	if story == null:
		return PackedStringArray(["剧情资源为空"])
	var errors := story.errors()
	if not errors.is_empty():
		return errors
	_nodes = story.nodes.duplicate(true)
	_title = story.title
	_start = story.start
	restart()
	return errors

func restart() -> void:
	_history.clear()
	_current = _start
	if not _current.is_empty():
		_record()

func advance() -> bool:
	if _current.is_empty() or _nodes[_current].type != "line":
		return false
	_current = _nodes[_current].next
	_record()
	return true

func back() -> bool:
	if _history.size() <= 1: return false
	_history.pop_back()
	_current = _history[-1].id
	_history[-1].erase("selected")
	return true

func choose(index: int) -> bool:
	if _current.is_empty() or _nodes[_current].type != "choice":
		return false
	var choices: Array = _nodes[_current].choices
	if index < 0 or index >= choices.size():
		return false
	_history[-1]["selected"] = choices[index].text
	_current = choices[index].next
	_record()
	return true

func snapshot() -> Dictionary:
	if _current.is_empty():
		return {}
	var node: Dictionary = _nodes[_current].duplicate(true)
	node["id"] = _current
	node["title"] = _title
	node["finished"] = node.type == "end"
	node["history"] = _history.duplicate(true)
	return node

func _record() -> void:
	var node: Dictionary = _nodes[_current]
	_history.append({"id": _current, "speaker": node.get("speaker", "旁白"), "text": node.text})
