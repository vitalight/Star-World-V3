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
 for index in range(5):
  var formal_id := "character_%03d" % (11 + index)
  var formal = load("res://content/data/%s.tres" % formal_id).appearance
  var actual = game.appearances[formal_id]
  check(actual.attack_sheet.resource_path == formal.attack_sheet.resource_path, "Game Test uses official actor animation: " + formal_id)
  var art_actual = art.catalog[formal_id]
  check(art_actual.attack_sheet.resource_path == formal.attack_sheet.resource_path, "Art Battle uses official animation: " + formal_id)
 var entries = load("res://devtools/art_test/asset_catalog.gd").characters()
 check(entries.size() == 25, "Art previews all 9 heroes and 16 monsters")
 for entry in entries:
  check(entry.attack.size() == 4 and (entry.move.size() == 1 if entry.kind == "enemy" else entry.move.is_empty()), "Art has action frames: " + entry.name)
 for index in 5:
  var appearance = load("res://content/data/character_%03d.tres" % (11 + index)).appearance
  check(appearance.attack_sheet.resource_path == "res://content/characters/character_%03d/attack_v1.png" % (11 + index) and appearance.attack_frames().size() == 4 and appearance.portrait == appearance.attack_frames()[0], "Formal actor uses its updated attack frames: " + str(11 + index))
 for index in 5:
  var appearance = load("res://content/data/enemy_%03d.tres" % (1 + index)).appearance
  var version := 2 if index == 4 else 1
  check(appearance.attack_frames().size() == 4 and appearance.attack_sheet.resource_path == "res://content/enemies/enemy_%03d/attack_v%d.png" % [1 + index, version], "Formal enemy has updated action frames: " + str(1 + index))
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
