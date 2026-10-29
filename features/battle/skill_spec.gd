@tool
class_name BattleSkillSpec
extends Resource
## Immutable authored data. SP, cooldown and active duration belong to Battle.
@export var content_id := ""
@export var display_name := ""
@export_multiline var description := ""
@export_enum("auto", "attack", "hit") var recovery := "auto"
@export var required := 5.0
@export var initial_sp := 0.0
@export var duration := 4.0
@export var multiplier := 1.0
@export var defense_multiplier := 1.0
@export var interval_multiplier := 1.0
@export var cost_gain := 0.0
@export_enum("manual", "automatic") var trigger := "manual"
@export var forward_range := 0
@export var hit_count := 1
@export_range(0.0, 1.0) var heal_damage_reduction := 0.0
@export var heal_buff_duration := 0.0

func configuration() -> Dictionary:
	return {"enabled": true, "name": display_name, "description": description,
		"recovery": recovery, "required": required, "initial_sp": initial_sp,
		"duration": duration, "multiplier": multiplier,
		"defense_multiplier": defense_multiplier,
		"interval_multiplier": interval_multiplier, "cost_gain": cost_gain,
		"trigger": trigger, "forward_range": forward_range, "hit_count": hit_count,
		"heal_damage_reduction": heal_damage_reduction, "heal_buff_duration": heal_buff_duration}

func errors() -> PackedStringArray:
	var result := PackedStringArray()
	for field in ["required", "multiplier", "defense_multiplier", "interval_multiplier"]:
		if not is_finite(get(field)) or get(field) <= 0: result.append("%s: 必须为有限正数" % field)
	for field in ["initial_sp", "cost_gain", "duration"]:
		if not is_finite(get(field)) or get(field) < 0: result.append("%s: 必须为有限非负数" % field)
	if initial_sp > required: result.append("initial_sp: 不能大于 required")
	if recovery not in ["auto", "attack", "hit"]: result.append("recovery: 可用值 auto/attack/hit")
	if trigger not in ["manual", "automatic"]: result.append("trigger: 可用值 manual/automatic")
	if forward_range < 0 or hit_count < 1: result.append("技能范围或攻击次数无效")
	if not is_finite(heal_damage_reduction) or heal_damage_reduction < 0 or heal_damage_reduction > 1 or not is_finite(heal_buff_duration) or heal_buff_duration < 0: result.append("治疗减伤参数无效")
	return result
