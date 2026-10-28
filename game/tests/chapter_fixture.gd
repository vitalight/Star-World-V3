extends RefCounted
## Replays use the same commands a player can submit; no state mutation.
static func operator_ids(id: String) -> Array:
	# Explicit player snapshots for these scripted battle replays, not level data.
	if id == "scene_0101B": return ["character_011", "character_012"]
	var result := ["character_011", "character_013", "character_014"]
	if id == "scene_0104B": result.append("character_015")
	return result

static func deployments(id: String) -> Array:
	if id == "scene_0101B": return [["character_011", Vector2i(2, 1), 3], ["character_012", Vector2i(3, 3), 2]]
	if id == "scene_0102B": return [["character_011", Vector2i(4, 1), 2], ["character_014", Vector2i(5, 3), 2], ["character_013", Vector2i(5, 2), 2]]
	var lower := 4 if id == "scene_0103B" else 5
	var result := [["character_011", Vector2i(5, 1), 2], ["character_014", Vector2i(5, lower), 2], ["character_013", Vector2i(5, 2), 2]]
	if id == "scene_0104B": result.append(["character_015", Vector2i(6, 3), 2])
	return result

static func replay(battle: RefCounted, id: String) -> Array:
	var rejected: Array = []
	var pending := deployments(id)
	battle.start()
	for second in 300:
		while not pending.is_empty() and battle.snapshot().cost >= battle.configuration().roster[pending[0][0]].cost:
			var result: Dictionary = battle.callv("deploy", pending.pop_front())
			if not result.ok: rejected.append(result)
		if id == "scene_0101B" and second == 100:
			for unit in battle.snapshot().units:
				if unit.roster_id == "character_012": battle.retreat(unit.id)
		if id == "scene_0101B" and second == 108:
			var result: Dictionary = battle.deploy("character_012", Vector2i(3, 3), 2)
			if not result.ok: rejected.append(result)
		if second % 3 == 0:
			for unit in battle.snapshot().units:
				if unit.sp + 0.000001 >= unit.skill.required and unit.skill_left <= 0: battle.activate_skill(unit.id)
		battle.advance(1)
		if battle.snapshot().phase != "running": break
	return rejected
