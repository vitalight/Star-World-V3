extends Resource
## A small dialogue graph. Concrete story content is supplied by the caller.
@export var title: String = ""
@export var start: String = ""
@export var nodes: Dictionary = {}

func errors() -> PackedStringArray:
	var result := PackedStringArray()
	if start.is_empty() or not nodes.has(start):
		result.append("起始节点不存在：" + start)
	for id in nodes:
		if not id is String or str(id).is_empty() or not nodes[id] is Dictionary:
			result.append("节点必须使用非空字符串 ID 和 Dictionary 数据")
			continue
		var node: Dictionary = nodes[id]
		_check_presentation(node, str(id), result)
		if not node.get("text") is String or not node.get("speaker", "") is String:
			result.append("%s：text / speaker 必须是字符串" % id)
		var kind = node.get("type", "")
		if kind == "line":
			_check_target(node.get("next"), str(id), result)
		elif kind == "choice":
			var choices = node.get("choices")
			if not choices is Array or choices.is_empty():
				result.append("%s：选择节点必须提供选项" % id)
				continue
			for choice in choices:
				if not choice is Dictionary or not choice.get("text") is String or str(choice.get("text", "")).is_empty():
					result.append("%s：选项必须提供非空 text" % id)
					continue
				_check_target(choice.get("next"), str(id), result)
		elif kind != "end":
			result.append("%s：未知节点类型 %s" % [id, kind])
	return result

func _check_presentation(node: Dictionary, id: String, result: PackedStringArray) -> void:
	if node.get("framing", "wide") not in ["wide", "left_close"]:
		result.append("%s：framing 必须是 wide 或 left_close" % id)
	if not node.get("background", "") is String or not node.get("speaker_actor", "") is String:
		result.append("%s：background / speaker_actor 必须是字符串" % id)
	var actors = node.get("actors", [])
	if not actors is Array or actors.size() > 2:
		result.append("%s：actors 必须为最多两人的数组" % id)
		return
	for actor in actors:
		if not actor is String or str(actor).is_empty():
			result.append("%s：actors 必须使用非空角色 ID" % id)
	if actors.size() == 2 and actors[0] == actors[1]:
		result.append("%s：出场角色不能重复" % id)
	if not node.get("screen_shake", false) is bool:
		result.append("%s：screen_shake 必须是布尔值" % id)
	for field in ["actor_shake", "actor_flip", "actor_mirrored", "actor_exit_left", "actor_exit_right"]:
		var targets = node.get(field, [])
		if not targets is Array:
			result.append("%s：%s 必须是角色 ID 数组" % [id, field])
		else:
			var seen := {}
			for actor in targets:
				if not actor is String or not actors.has(actor) or seen.has(actor):
					result.append("%s：%s 必须为已出场且不重复的角色 ID" % [id, field])
				seen[actor] = true
	if node.has("actor_exit"):
		result.append("%s：actor_exit 已改为 actor_exit_left / actor_exit_right" % id)
	var left = node.get("actor_exit_left", [])
	var right = node.get("actor_exit_right", [])
	if left is Array and right is Array:
		for actor in left:
			if right.has(actor): result.append("%s：同一角色不能同时向左和向右离场" % id)
	var active = node.get("speaker_actor", "")
	if active is String and not active.is_empty() and not actors.has(active):
		result.append("%s：说话角色必须在 actors 中出场" % id)

func _check_target(target: Variant, id: String, result: PackedStringArray) -> void:
	if not target is String or not nodes.has(target):
		result.append("%s：跳转目标不存在：%s" % [id, target])
