extends SceneTree
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
 if not ok:
  failures += 1
  push_error(message)
func run() -> void:
 var game = load("res://game/battle/battle_scene.tscn").instantiate()
 root.add_child(game)
 game.set_process(false)
 var art = load("res://devtools/art_test/battle_stage.gd").new()
 root.add_child(art)
 art.set_process(false)
 var keys = ["guard", "tank", "sniper", "caster", "medic"]
 for index in range(5):
  var id: int = [1, 3, 4, 5, 6][index]
  var expected = load("res://content/data/character_%03d.tres" % id).appearance
  for entry in [{"name":"Game Test", "catalog":game.appearances}, {"name":"Art Battle", "catalog":art.catalog}]:
   var actual = entry.catalog[keys[index]]
   check(actual.atlas.resource_path == expected.atlas.resource_path and actual.atlas_row == expected.atlas_row, entry.name + ": " + keys[index] + " uses configured actor atlas row")
 var entries = load("res://devtools/art_test/asset_catalog.gd").characters()
 for index in range(5):
  var filename = "hero-atlas-%d.png" % (101 + index)
  check(entries.any(func(entry): return entry.source == filename and entry.row == 0), "Art Character/Animation includes " + filename)
 game.free()
 art.free()
 print("DEVTOOLS ATLAS: 15 checks, %d failures" % failures)
 quit(1 if failures else 0)
