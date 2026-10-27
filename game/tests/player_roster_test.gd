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
 progress.pending_after = "scene_002"
 progress.finish_story(catalog.levels.keys(), catalog.recruits, catalog.departures, catalog.returns)
 check(progress.operators.has("character_012") and not progress.available_operators().has("character_012"), "Abducted cat remains owned but cannot deploy")
 check(progress.available_operators() == ["character_011", "character_013", "character_014"], "New recruits join player roster")
 progress.pending_after = "scene_005"
 progress.finish_story(catalog.levels.keys(), catalog.recruits, catalog.departures, catalog.returns)
 check(progress.available_operators().size() == 3 and progress.selected == "scene_003", "Home cleanup leads to rescue without early doctor recruitment")
 progress.pending_after = "scene_003"
 progress.finish_story(catalog.levels.keys(), catalog.recruits, catalog.departures, catalog.returns)
 check(progress.available_operators().size() == 4, "Rescued doctor joins player roster")
 progress.pending_after = "scene_004"
 progress.finish_story(catalog.levels.keys(), catalog.recruits, catalog.departures, catalog.returns)
 check(progress.save(SAVE) == OK, "Player roster and availability save")
 var player = Player.instantiate()
 player.save_path = SAVE
 root.add_child(player)
 player.progress.selected = "scene_002"
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
 player.progress.selected = "scene_003"
 player.start_battle()
 await process_frame
 check(player.battle_scene.configuration.roster.keys() == expected, "Other stages retain current player roster")
 player.queue_free()
 await process_frame
 # Future return events restore availability without granting a duplicate operator.
 progress.completed.erase("scene_004")
 progress.pending_after = "scene_004"
 progress.finish_story(catalog.levels.keys(), catalog.recruits, catalog.departures, {"scene_004":["character_012"]})
 check(progress.available_operators().size() == 5 and progress.operators.size() == 5, "Cat can rejoin without duplicate ownership")
 progress.pending_after = "scene_002"
 progress.finish_story(catalog.levels.keys(), catalog.recruits, catalog.departures, {})
 check(progress.available_operators().has("character_012"), "Replaying old story does not repeat departure")
 progress.save(SAVE)
 var returned = Progress.new()
 returned.load_progress(SAVE, catalog.levels.keys())
 returned.configure_operators(catalog.starting_operators, catalog.recruits, catalog.characters.keys(), catalog.departures, catalog.returns)
 check(returned.available_operators().has("character_012"), "Returned status survives save/load")
 # Existing version-one saves migrate using progress rather than selected level.
 var file = FileAccess.open(SAVE, FileAccess.WRITE)
 file.store_string("[campaign]\nversion=1\ncompleted=[\"scene_002\",\"scene_003\",\"scene_004\"]\nselected=\"scene_002\"\nstarted=true\n")
 file.close()
 var legacy = Progress.new()
 legacy.load_progress(SAVE, catalog.levels.keys())
 legacy.configure_operators(catalog.starting_operators, catalog.recruits, catalog.characters.keys(), catalog.departures, catalog.returns)
 check(legacy.completed == ["scene_002", "scene_005", "scene_003", "scene_004"], "Old completed chapter survives inserted home battle")
 check(legacy.available_operators() == expected, "Old save migrates chapter-end squad while first stage selected")
 file = FileAccess.open(SAVE, FileAccess.WRITE)
 file.store_string("[campaign]\nversion=2\ncompleted=[\"scene_002\"]\nselected=\"scene_003\"\nstarted=true\n")
 file.close()
 legacy.load_progress(SAVE, catalog.levels.keys())
 check(legacy.completed == ["scene_002"] and legacy.selected == "scene_005", "Old in-progress rescue selects new cleanup stage without losing first victory")
 file = FileAccess.open(SAVE, FileAccess.WRITE)
 file.store_string("[campaign]\nversion=2\ncompleted=[\"scene_002\"]\nselected=\"scene_003\"\npending_after=\"scene_003\"\nstarted=true\n")
 file.close()
 legacy.load_progress(SAVE, catalog.levels.keys())
 check(legacy.completed == ["scene_002", "scene_005"] and legacy.pending_after == "scene_003", "Old pending rescue victory survives inserted stage")
 for level in catalog.levels.values(): check(not level.has("roster"), "Level metadata has no player roster")
 var map = load("res://content/scenes/scene_001/map.tscn").instantiate()
 check(map.level.get("actors") == null and map.level.get("roster") == null, "Development level contains no actor references")
 map.free()
 print("PLAYER ROSTER: %d checks, %d failures" % [checks,failures])
 quit(1 if failures else 0)
