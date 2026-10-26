@tool
class_name SkillDefinition
extends "res://features/battle/skill_spec.gd"
## Skill authoring resource; configuration() exports only battle rules.
@export var icon: Texture2D

func errors() -> PackedStringArray:
	var result := super.errors()
	if icon == null: result.append("icon: 技能图标不能为空")
	return result
