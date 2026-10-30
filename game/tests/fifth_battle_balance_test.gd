extends SceneTree
const Catalog = preload("res://game/content/content_catalog.gd")
const Battle = preload("res://features/battle/battle.gd")

func _initialize() -> void:
 var catalog = Catalog.new()
 catalog.reload()
 var map = load(catalog.levels.scene_0104C.map).instantiate()
 var config: Dictionary = catalog.configuration("scene_0104C", map)
 map.free()
 var total := 0
 for wave in config.waves: total += wave.count
 var good = replay(config, 2)
 var bad = replay(config, 0)
 print("FIFTH BATTLE: enemies=%d, covered=%s life=%d killed=%d, wrong-facing=%s killed=%d" % [total, good.phase, good.life, good.killed, bad.phase, bad.killed])
 quit(0 if total == 50 and good.phase == "victory" and bad.phase == "defeat" else 1)

func replay(config: Dictionary, facing: int) -> Dictionary:
 var battle = Battle.new(config)
 var pending = [["character_011", Vector2i(5, 1), facing], ["character_014", Vector2i(5, 3), facing], ["character_013", Vector2i(5, 2), facing], ["character_015", Vector2i(6, 2), facing]]
 battle.start()
 for second in 500:
  while not pending.is_empty() and battle.snapshot().cost >= config.roster[pending[0][0]].cost:
   var result: Dictionary = battle.callv("deploy", pending.pop_front())
   if not result.ok: return {"phase": "rejected", "life": 0, "killed": 0}
  for unit in battle.snapshot().units:
   if unit.skill.enabled and unit.skill.trigger == "manual" and unit.sp >= unit.skill.required and unit.skill_left <= 0:
    battle.activate_skill(unit.id)
  battle.advance(1)
  if battle.snapshot().phase != "running": break
 return battle.snapshot()
