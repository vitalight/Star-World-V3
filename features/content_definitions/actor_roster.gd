@tool
extends Resource
## Player or preview squad; kept separate from level definitions.
const Actor = preload("res://features/content_definitions/actor_definition.gd")
@export var actors: Dictionary[String, Actor] = {}

func configuration() -> Dictionary:
	var result := {}
	var keys := actors.keys()
	keys.sort_custom(func(a, b): return actors[a].stats.content_id.naturalnocasecmp_to(actors[b].stats.content_id) < 0)
	for key in keys: result[key] = actors[key].stats.configuration()
	return result

func appearances() -> Dictionary:
	var result := {}
	for key in actors: result[key] = actors[key].appearance
	return result

func skill_icons() -> Dictionary:
	var result := {}
	for key in actors:
		var skill = actors[key].stats.skill_spec
		if skill and skill.get("icon") != null: result[key] = skill.icon
	return result

func errors() -> PackedStringArray:
	var result := PackedStringArray()
	if actors.is_empty(): result.append("Roster: 干员列表不能为空")
	for key in actors:
		if actors[key] == null or actors[key].stats == null or actors[key].appearance == null:
			result.append("Roster %s: 缺少角色数值或外观" % key)
		else:
			for message in actors[key].stats.errors(): result.append("Roster %s: %s" % [key, message])
	return result
