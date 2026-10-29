@tool
extends Resource
const SkillSpec = preload("res://features/battle/skill_spec.gd")
## Scene-free, Inspector-editable combat data. No appearance references.
@export var content_id := ""
@export var display_name := ""
@export_group("Combat")
@export var max_hp := 600.0
@export var attack := 50.0
@export var defense := 8.0
@export_range(0, 95) var resistance := 0.0
@export_enum("physical", "arts", "true") var damage_type := "physical"
@export var interval := 0.8
@export var windup := 0.2
@export_group("Operator")
@export_enum("melee", "ranged", "healer") var role := "melee"
@export var cost := 10.0
@export var redeploy_time := 5.0
@export var block := 2
@export var anti_air := false
@export var range_cells: Array[Vector2i] = [Vector2i.ZERO, Vector2i.RIGHT]
@export var passive := false
@export var skill_spec: SkillSpec
@export_group("Legacy Sample Skill")
## Compatibility for existing development samples. Formal content uses skill_spec.
@export var skill := {"enabled": false, "recovery": "auto", "required": 5.0, "duration": 4.0, "multiplier": 2.0}
@export_group("Enemy")
@export var speed := 0.85
@export var ranged := false
@export var attack_range := 3.0
@export var flying := false
@export var leak_damage := 1

func configuration(enemy := false) -> Dictionary:
	var result := {"name": display_name, "max_hp": max_hp, "attack": attack, "defense": defense,
		"resistance": resistance, "damage_type": damage_type, "interval": interval, "windup": windup}
	if enemy:
		result.merge({"speed": speed, "ranged": ranged, "range": attack_range, "flying": flying, "leak_damage": leak_damage})
	else:
		result.merge({"role": role, "cost": cost, "redeploy_time": redeploy_time, "block": block,
			"anti_air": anti_air, "range": range_cells.duplicate(), "passive": passive,
			"skill": skill_spec.configuration() if skill_spec else skill.duplicate(true)})
	return result

func errors() -> PackedStringArray:
	var result := PackedStringArray()
	if content_id.is_empty(): result.append("content_id 不能为空")
	for field in ["max_hp", "attack", "defense", "resistance", "interval", "windup", "cost", "redeploy_time", "speed", "attack_range"]:
		if not is_finite(get(field)): result.append("%s: 必须为有限数值" % field)
	if resistance < 0 or resistance > 95: result.append("resistance: 必须在 0 至 95 之间")
	if role not in ["melee", "ranged", "healer"]: result.append("role: 可用值 melee/ranged/healer")
	if damage_type not in ["physical", "arts", "true"]: result.append("damage_type: 可用值 physical/arts/true")
	if range_cells.is_empty(): result.append("range_cells: 攻击范围不能为空")
	if attack_range < 0: result.append("attack_range: 不可为负")
	if max_hp <= 0 or attack < 0 or defense < 0 or interval <= 0 or windup < 0 or windup > interval:
		result.append("生命、攻击、防御或攻击时间非法")
	if cost < 0 or redeploy_time < 0 or block < 0 or speed < 0 or leak_damage < 1:
		result.append("费用、冷却、阻挡、移速或漏怪伤害非法")
	if skill_spec:
		result.append_array(skill_spec.errors())
		return result
	if skill.get("required", 5.0) <= 0 or skill.get("duration", 3.0) < 0 or skill.get("recovery", "auto") not in ["auto", "attack", "hit"]:
		result.append("技能配置非法")
	if skill.get("multiplier", 2.0) <= 0 or skill.get("defense_multiplier", 1.0) <= 0 or skill.get("interval_multiplier", 1.0) <= 0:
		result.append("技能倍率必须大于零")
	if skill.get("cost_gain", 0.0) < 0: result.append("技能回费不可为负")
	return result
