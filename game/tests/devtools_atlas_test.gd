extends SceneTree
var failures := 0
var checks := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
 checks += 1
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
  var formal_id := "character_%03d" % (11 + index)
  var formal = load("res://content/data/%s.tres" % formal_id).appearance
  var actual = game.appearances[formal_id]
  check(actual.atlas.resource_path == formal.atlas.resource_path and actual.atlas_row == formal.atlas_row, "Game Test uses official actor atlas row: " + formal_id)
  var sample = load("res://content/data/character_%03d.tres" % [1, 3, 4, 5, 6][index]).appearance
  var art_actual = art.catalog[keys[index]]
  check(art_actual.atlas.resource_path == sample.atlas.resource_path and art_actual.atlas_row == sample.atlas_row, "Art Battle uses configured sample atlas row: " + keys[index])
 var entries = load("res://devtools/art_test/asset_catalog.gd").characters()
 check(entries.size() == 28, "Art previews all 12 heroes and 16 monsters")
 for filename in ["hero-atlas-101-v2.png", "hero-atlas-102-v2.png", "hero-atlas-103-v2.png", "enemy-atlas-101.png", "enemy-atlas-102.png", "enemy-atlas-103.png", "enemy-atlas-104.png"]:
  for row in 4:
   check(entries.any(func(entry): return entry.source == filename and entry.row == row), "Art includes %s row %d" % [filename, row + 1])
 for index in 5:
  var appearance = load("res://content/data/character_%03d.tres" % (11 + index)).appearance
  var source = "hero-atlas-101-v2.png" if index < 4 else "hero-atlas-102-v2.png"
  check(appearance.atlas.get_image().get_data() == load("res://Human/StarterContent/character/" + source).get_image().get_data() and appearance.atlas_row == [1, 2, 3, 4, 1][index], "Formal actor identity matches supplied atlas: " + str(11 + index))
 for index in 5:
  var appearance = load("res://content/data/enemy_%03d.tres" % (1 + index)).appearance
  check(appearance.atlas.get_image().get_data() == load("res://Human/StarterContent/character/enemy-atlas-101.png").get_image().get_data() and appearance.atlas_row == [1, 2, 3, 3, 4][index], "Formal enemy matches supplied role: " + str(1 + index))
 var catalog = preload("res://game/content/content_catalog.gd").new()
 catalog.reload()
 var filenames = ["chapter01_01_home_anomaly_v1.png", "chapter01_02_roadside_rescue_v2.png", "chapter01_03_oriental_pearl_node_v2.png"]
 for index in 3:
  var key := "background_%03d" % (index + 1)
  var path: String = catalog.backgrounds.get(key, "")
  var source: String = "res://Human/StarterContent/story/chapter01/" + filenames[index]
  var exists := ResourceLoader.exists(path) and ResourceLoader.exists(source)
  check(exists, "Registered background and source exist: " + key)
  if exists:
   check(load(path).get_image().get_data() == load(source).get_image().get_data(), "Formal story uses supplied chapter background: " + key)
 game.free()
 art.free()
 print("DEVTOOLS ATLAS: %d checks, %d failures" % [checks, failures])
 quit(1 if failures else 0)
