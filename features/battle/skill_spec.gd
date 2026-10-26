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

func configuration() -> Dictionary:
	return {"enabled": true, "name": display_name, "description": description,
		"recovery": recovery, "required": required, "initial_sp": initial_sp,
		"duration": duration, "multiplier": multiplier,
		"defense_multiplier": defense_multiplier,
		"interval_multiplier": interval_multiplier, "cost_gain": cost_gain}

func errors() -> PackedStringArray:
	var result := PackedStringArray()
	for field in ["required", "duration", "multiplier", "defense_multiplier", "interval_multiplier"]:
		if not is_finite(get(field)) or get(field) <= 0: result.append("%s: 必须为有限正数" % field)
	for field in ["initial_sp", "cost_gain"]:
		if not is_finite(get(field)) or get(field) < 0: result.append("%s: 必须为有限非负数" % field)
	if initial_sp > required: result.append("initial_sp: 不能大于 required")
	if recovery not in ["auto", "attack", "hit"]: result.append("recovery: 可用值 auto/attack/hit")
	return result
