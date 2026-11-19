extends SceneTree

const Catalog = preload("res://game/content/content_catalog.gd")
const Battle = preload("res://features/battle/battle.gd")
const Progress = preload("res://game/player/campaign_progress.gd")
var failures := 0

func _initialize() -> void:
	var c = Catalog.new()
	c.reload()
	check(c.errors.is_empty(), "catalog loads")
	var ids: Array = c.levels.keys()
	var progress = Progress.new()
	for id in ids:
		if id == "scene_0201A": break
		progress.completed.append(id)
	progress.configure_operators(c.starting_operators, c.recruits, c.characters.keys(), c.departures, c.returns)
	check(progress.unlocked("scene_0201A", ids), "completed chapter one unlocks chapter two")
	check(not progress.available_operators().has("character_012"), "cat remains away")
	progress.pending_after = "scene_0201A"
	progress.finish_story(ids, c.recruits, c.departures, c.returns)
	progress.pending_after = "scene_0201B"
	progress.finish_story(ids, c.recruits, c.departures, c.returns)
	check(progress.available_operators().has("character_016") and not progress.available_operators().has("character_017"), "Tiger joins after first battle")
	for id in ["scene_0205A", "scene_0205B", "scene_0202A"]:
		progress.pending_after = id
		progress.finish_story(ids, c.recruits, c.departures, c.returns)
	check(not progress.available_operators().has("character_017"), "Sugar has not joined before the storm battle")
	progress.pending_after = "scene_0202B"
	progress.finish_story(ids, c.recruits, c.departures, c.returns)
	check(progress.available_operators().has("character_017"), "Sugar joins after the storm battle")
	var plans := {
		"scene_0201B": [["character_016", Vector2i(6, 3), 2], ["character_014", Vector2i(3, 2), 2], ["character_015", Vector2i(5, 4), 3], ["character_013", Vector2i(5, 2), 3], ["character_011", Vector2i(7, 3), 2]],
		"scene_0205B": [["character_016", Vector2i(7, 3), 2], ["character_014", Vector2i(4, 3), 2], ["character_013", Vector2i(6, 2), 3], ["character_015", Vector2i(6, 4), 3], ["character_011", Vector2i(8, 3), 2]],
		"scene_0202B": [["character_016", Vector2i(6, 1), 2], ["character_014", Vector2i(6, 3), 2], ["character_011", Vector2i(5, 4), 2], ["character_013", Vector2i(4, 2), 2], ["character_015", Vector2i(5, 2), 0]],
		"scene_0206B": [["character_016", Vector2i(6, 2), 2], ["character_014", Vector2i(4, 4), 2], ["character_011", Vector2i(7, 1), 3], ["character_015", Vector2i(5, 1), 0], ["character_013", Vector2i(6, 1), 3], ["character_017", Vector2i(6, 3), 3]],
		"scene_0203B": [["character_016", Vector2i(5, 2), 2], ["character_017", Vector2i(3, 1), 1], ["character_014", Vector2i(7, 3), 2], ["character_015", Vector2i(6, 4), 3], ["character_013", Vector2i(4, 3), 2], ["character_011", Vector2i(8, 3), 2]]}
	for id in plans:
		var map = load(c.levels[id].map).instantiate()
		check(c.map_errors(id, map).is_empty(), id + " map and waves are valid")
		check(map.background_texture.resource_path == "res://content/terrains/terrain_004/backdrop.png" and map.terrain_atlas.resource_path == "res://content/terrains/terrain_004/atlas.png", id + " uses chapter shared art")
		var b = Battle.new(c.configuration(id, map))
		map.free()
		var pending: Array = plans[id].duplicate(true)
		b.start()
		for sec in 300:
			while not pending.is_empty() and b.snapshot().cost >= b.configuration().roster[pending[0][0]].cost:
				var item: Array = pending.pop_front()
				var result: Dictionary = b.callv("deploy", item)
				check(result.ok, id + " accepts planned deployment " + str(item) + " " + result.reason)
			for unit in b.snapshot().units:
				if unit.skill.trigger == "manual" and unit.sp + 0.000001 >= unit.skill.required and unit.skill_left <= 0: b.activate_skill(unit.id)
			b.advance(1.0)
			if b.snapshot().phase != "running": break
		print(id, " ", b.snapshot().phase, " life=", b.snapshot().life, " killed=", b.snapshot().killed, " time=", b.snapshot().time)
		check(b.snapshot().phase == "victory", id + " replay reaches victory")
	print("CHAPTER TWO: ", failures, " failures")
	quit(1 if failures else 0)

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
