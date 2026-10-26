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
 check(entries.size() == 28, "Art previews all 12 heroes and 16 monsters")
 for filename in ["hero-atlas-101-v2.png", "hero-atlas-102-v2.png", "hero-atlas-103-v2.png", "enemy-atlas-101.png", "enemy-atlas-102.png", "enemy-atlas-103.png", "enemy-atlas-104.png"]:
  for row in 4:
   check(entries.any(func(entry): return entry.source == filename and entry.row == row), "Art includes %s row %d" % [filename, row + 1])
 for index in 5:
  var appearance = load("res://content/data/character_%03d.tres" % (11 + index)).appearance
  var source = "hero-atlas-101-v2.png" if index < 4 else "hero-atlas-102-v2.png"
  check(appearance.atlas.get_image().get_data() == load("res://Human/StarterContent/character/" + source).get_image().get_data() and appearance.atlas_row == [1, 2, 3, 4, 1][index], "Formal actor identity matches supplied atlas: " + str(11 + index))
 for index in 4:
  var appearance = load("res://content/data/enemy_%03d.tres" % (1 + index)).appearance
  check(appearance.atlas.get_image().get_data() == load("res://Human/StarterContent/character/enemy-atlas-101.png").get_image().get_data() and appearance.atlas_row == [1, 2, 4, 3][index], "Formal enemy matches supplied role: " + str(1 + index))
 for index in 3:
  var filenames = ["chapter01_01_home_anomaly_v1.png", "chapter01_02_roadside_rescue_v2.png", "chapter01_03_oriental_pearl_node_v2.png"]
  check(load("res://content/scenes/scene_%03d/background.png" % (2 + index)).get_image().get_data() == load("res://Human/StarterContent/story/chapter01/" + filenames[index]).get_image().get_data(), "Formal story uses supplied chapter background " + str(index + 1))
 game.free()
 art.free()
 print("DEVTOOLS ATLAS: 51 checks, %d failures" % failures)
 quit(1 if failures else 0)
