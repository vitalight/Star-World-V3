extends SceneTree
const Player = preload("res://game/player/player_mode.tscn")
const Progress = preload("res://game/player/campaign_progress.gd")
const Catalog = preload("res://game/content/content_catalog.gd")
const SAVE = "res://temp/roster_replay_test.cfg"
var failures := 0
var checks := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
 checks += 1
 if not ok:
  failures += 1
  push_error(label)
func run() -> void:
 var catalog = Catalog.new()
 catalog.reload()
 check(catalog.errors.is_empty(), "Roster acquisition data validates")
 var progress = Progress.new()
 var fresh = FileAccess.open(SAVE, FileAccess.WRITE)
 fresh.store_string("")
 fresh.close()
 progress.load_progress(SAVE, catalog.levels.keys())
 progress.configure_operators(catalog.starting_operators, catalog.recruits, catalog.characters.keys(), catalog.departures, catalog.returns)
 check(progress.available_operators() == ["character_011", "character_012"], "New player starts with protagonist and cat")
 progress.completed.append("scene_0101A")
 progress.pending_after = "scene_0101B"
 progress.finish_story(catalog.levels.keys(), catalog.recruits, catalog.departures, catalog.returns)
 check(progress.operators.has("character_012") and not progress.available_operators().has("character_012"), "Abducted cat remains owned but cannot deploy")
 check(progress.available_operators() == ["character_011", "character_013", "character_014"], "New recruits join player roster")
 progress.completed.append("scene_0102A")
 progress.pending_after = "scene_0102B"
 progress.finish_story(catalog.levels.keys(), catalog.recruits, catalog.departures, catalog.returns)
 check(progress.available_operators().size() == 3 and progress.selected == "scene_0103A", "Home cleanup leads to rescue without early doctor recruitment")
 progress.completed.append("scene_0103A")
 progress.pending_after = "scene_0103B"
 progress.finish_story(catalog.levels.keys(), catalog.recruits, catalog.departures, catalog.returns)
 check(progress.available_operators().size() == 4, "Rescued doctor joins player roster")
 progress.completed.append("scene_0104A")
 progress.pending_after = "scene_0104B"
 progress.finish_story(catalog.levels.keys(), catalog.recruits, catalog.departures, catalog.returns)
 check(progress.save(SAVE) == OK, "Player roster and availability save")
 var player = Player.instantiate()
 player.save_path = SAVE
 root.add_child(player)
 player.progress.selected = "scene_0101B"
 player.start_battle()
 await process_frame
 var expected = ["character_011", "character_013", "character_014", "character_015"]
 check(player.progress.available_operators() == expected, "Reload retains current roster and cat absence")
 var opening_cast = ["character_011", "character_012"]
 check(player.battle_scene.configuration.roster.keys() == opening_cast, "Replay 1-1 has only protagonist and cat")
 check(player.battle_scene.hud.cards.keys() == opening_cast, "1-1 deployment cards contain only opening cast")
 check(player.battle_scene.appearances.has("character_012") and not player.battle_scene.appearances.has("character_015"), "1-1 restores cat appearance and excludes later recruit")
 check(player.battle_scene.skill_icons.keys() == opening_cast, "1-1 skill icons match opening cast")
 player.battle_scene.reset()
 check(player.battle_scene.configuration.roster.keys() == opening_cast, "Retry retains opening cast")
 player.battle_scene.reload_level()
 await process_frame
 check(player.battle_scene.configuration.roster.keys() == opening_cast, "Reload retains opening cast")
 check(player.progress.available_operators() == expected, "Opening cast does not alter saved roster or cat absence")
 player.progress.selected = "scene_0103B"
 player.start_battle()
 await process_frame
 var mid_cast = ["character_011", "character_013", "character_014"]
 check(player.battle_scene.configuration.roster.keys() == mid_cast, "Replaying 1-3 uses the fixed team without the later doctor")
 for id in ["scene_0102B", "scene_0103B", "scene_0104B", "scene_0104C"]:
  var fixed_cast = mid_cast if id in ["scene_0102B", "scene_0103B"] else expected
  check(catalog.battle_operator_ids(id, ["character_012"]) == fixed_cast, id + " ignores current player roster")
 player.catalog.levels.scene_0103B.roster_mode = "player"
 player.show_levels()
 await process_frame
 var checkbox: CheckBox = player.find_child("Squad_character_015", true, false)
 check(checkbox != null, "Player roster mode offers available operators")
 if checkbox: checkbox.button_pressed = false
 check(player.catalog.battle_operator_ids("scene_0103B", player.selected_squad) == mid_cast, "Player mode resolves the selected squad")
 var selected_map = load(player.catalog.levels.scene_0103B.map).instantiate()
 check(player.catalog.configuration("scene_0103B", selected_map, player.selected_squad).roster.keys() == mid_cast, "Selected squad reaches battle configuration")
 selected_map.free()
 for id in mid_cast:
  var selected: CheckBox = player.find_child("Squad_" + id, true, false)
  if selected: selected.button_pressed = false
 var action: Button = player.find_child("StartAction", true, false)
 check(action != null and action.disabled, "Player squad cannot be empty")
 check(player.progress.available_operators() == expected, "Selecting a squad does not change ownership")
 player.queue_free()
 await process_frame
 # Future return events restore availability without granting a duplicate operator.
 progress.completed.erase("scene_0104B")
 progress.pending_after = "scene_0104B"
 progress.finish_story(catalog.levels.keys(), catalog.recruits, catalog.departures, {"scene_0104B":["character_012"]})
 check(progress.available_operators().size() == 5 and progress.operators.size() == 5, "Cat can rejoin without duplicate ownership")
 progress.pending_after = "scene_0101B"
 progress.finish_story(catalog.levels.keys(), catalog.recruits, catalog.departures, {})
 check(progress.available_operators().has("character_012"), "Replaying old story does not repeat departure")
 progress.save(SAVE)
 var returned = Progress.new()
 returned.load_progress(SAVE, catalog.levels.keys())
 returned.configure_operators(catalog.starting_operators, catalog.recruits, catalog.characters.keys(), catalog.departures, catalog.returns)
 check(returned.available_operators().has("character_012"), "Returned status survives save/load")
 # Version-one completed chapter and version-two pending wins migrate.
 var file = FileAccess.open(SAVE, FileAccess.WRITE)
 file.store_string("[campaign]\nversion=1\ncompleted=[\"scene_002\",\"scene_003\",\"scene_004\"]\nselected=\"scene_002\"\nstarted=true\n")
 file.close()
 var legacy = Progress.new()
 legacy.load_progress(SAVE, catalog.levels.keys())
 legacy.configure_operators(catalog.starting_operators, catalog.recruits, catalog.characters.keys(), catalog.departures, catalog.returns)
 check(legacy.completed.size() == 10, "Old completed chapter includes epilogue")
 check(legacy.available_operators() == expected, "Old save migrates roster")
 var finished_save := ConfigFile.new()
 finished_save.set_value("campaign", "version", 3)
 finished_save.set_value("campaign", "completed", ["scene_0101A", "scene_0101B", "scene_0102A", "scene_0102B", "scene_0103A", "scene_0103B", "scene_0104A", "scene_0104B", "scene_0105A"])
 finished_save.set_value("campaign", "selected", "scene_0105A")
 finished_save.set_value("campaign", "started", true)
 finished_save.save(SAVE)
 var finished = Progress.new()
 finished.load_progress(SAVE, catalog.levels.keys())
 check(finished.completed.size() == 10 and finished.completed.has("scene_0104C"), "Finished save gains inserted final battle")
 file = FileAccess.open(SAVE, FileAccess.WRITE)
 file.store_string("[campaign]\nversion=2\ncompleted=[\"scene_002\"]\nselected=\"scene_003\"\npending_after=\"scene_003\"\nstarted=true\n")
 file.close()
 legacy.load_progress(SAVE, catalog.levels.keys())
 check(legacy.completed == ["scene_0101A", "scene_0101B", "scene_0102A", "scene_0102B", "scene_0103A"] and legacy.pending_after == "scene_0103B", "Pending rescue victory migrates with inserted battle")
 for level in catalog.levels.values(): check(not level.has("roster"), "Level metadata does not replace the saved player roster")
 var map = load("res://content/scenes/scene_001/map.tscn").instantiate()
 check(map.level.get("actors") == null and map.level.get("roster") == null, "Development level contains no actor references")
 map.free()
 print("PLAYER ROSTER: %d checks, %d failures" % [checks,failures])
 quit(1 if failures else 0)
