extends SceneTree
const Cues = preload("res://content/audio/cues.tres")
const BattleAudio = preload("res://game/adapters/battle_audio.gd")
const Settings = preload("res://features/audio/audio_settings.gd")
const Player = preload("res://game/player/player_mode.tscn")
const SAVE := "res://temp/audio/flow_progress.cfg"
const AUDIO := "res://temp/audio/settings.cfg"
var checks := 0
var failures := 0

class Recorder extends RefCounted:
	var played: Array[String] = []
	func play_sfx(id: String) -> bool:
		played.append(id)
		return true

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)

func settle() -> void:
	for frame in 5: await process_frame

func capture(name: String) -> void:
	if not ("--capture" in OS.get_cmdline_user_args()) or DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://temp/audio/" + name + ".png")

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://temp/audio")
	for path in [SAVE, AUDIO]:
		if FileAccess.file_exists(path): DirAccess.remove_absolute(path)
	_check_manifest()
	_check_mapping()
	await _check_product_flow()
	print("Audio integration: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

func _check_manifest() -> void:
	check(Cues.errors().is_empty(), "Cue manifest has no structural errors: %s" % [Cues.errors()])
	check(is_equal_approx(Cues.find("sfx_attack").start_offset, 0.06) and Cues.find("sfx_hit").start_offset == 0.0 and Cues.find("sfx_heal").start_offset == 0.0, "Attack starts earlier without shifting hit or healing cues")
	check(is_equal_approx(db_to_linear(Cues.find("music_battle").volume_db - Cues.find("music_main").volume_db), 0.8), "Battle music is 80 percent of its previous level")
	for id in ["music_main", "music_battle", "music_tension", "music_calm"]:
		var cue = Cues.find(id)
		check(cue != null, "Music cue exists: " + id)
		if cue == null: continue
		check(cue.stream is AudioStreamMP3, "Music cue is an imported mp3: " + id)
		check(cue.stream != null and cue.stream.loop, "Music cue loops: " + id)
	for id in BattleAudio.CUE_IDS:
		check(Cues.find(id) != null, "Battle cue exists in content: " + id)

func _check_mapping() -> void:
	check(BattleAudio.cue_for({"type": "deploy"}) == "sfx_deploy", "Deploy cue")
	check(BattleAudio.cue_for({"type": "route_warning"}) == "sfx_notify", "Route warning cue")
	check(BattleAudio.cue_for({"type": "attack_start"}) == "sfx_attack", "Attack cue")
	check(BattleAudio.cue_for({"type": "damage", "friendly": true}) == "sfx_hit", "Friendly damage cue")
	check(BattleAudio.cue_for({"type": "damage", "friendly": false}) == "sfx_hurt", "Incoming damage cue")
	check(BattleAudio.cue_for({"type": "heal"}) == "sfx_heal", "Heal cue")
	check(BattleAudio.cue_for({"type": "death", "side": "enemy"}) == "sfx_enemy_death", "Enemy death cue")
	check(BattleAudio.cue_for({"type": "death"}) == "sfx_unit_death", "Operator death cue")
	check(BattleAudio.cue_for({"type": "finished", "phase": "victory"}) == "sfx_victory", "Victory cue")
	check(BattleAudio.cue_for({"type": "finished", "phase": "defeat"}) == "sfx_defeat", "Defeat cue")
	check(BattleAudio.cue_for({"type": "unblock"}) == "" and BattleAudio.cue_for({"type": "unknown"}) == "", "Unmapped events stay silent")
	var recorder = Recorder.new()
	BattleAudio.new(recorder).sync({}, [
		{"type": "damage", "friendly": true}, {"type": "damage", "friendly": true},
		{"type": "attack_start"}, {"type": "unblock"}])
	check(recorder.played == ["sfx_hit", "sfx_attack"], "One cue per batch: %s" % [recorder.played])
	var silent = Recorder.new()
	BattleAudio.new().sync({}, [{"type": "attack_start"}])
	BattleAudio.new(silent).sync({}, [])
	check(silent.played.is_empty(), "Empty batch plays nothing")

func _check_product_flow() -> void:
	var player = Player.instantiate()
	player.save_path = SAVE
	player.audio_settings_path = AUDIO
	root.add_child(player)
	await settle()
	check(player.audio != null, "Product owns an audio director")
	check(player.audio.current_music_id == "music_main", "Menu music is selected")
	player.show_story("scene_0101A", "story")
	await settle()
	check(player.audio.current_music_id == "music_tension", "First story uses configured music")
	for id in ["scene_0102A", "scene_0103A", "scene_0104A"]:
		player.show_story(id, "story")
		await settle()
		check(player.audio.current_music_id == "music_tension", id + " uses tension music")
	player.show_story("scene_0105A", "story")
	await settle()
	check(player.audio.current_music_id == "music_calm", "Final story uses calm music")
	player.catalog.levels["scene_0105A"].music = ""
	player.show_story("scene_0105A", "story")
	await settle()
	check(player.audio.current_music_id == "music_main", "Unconfigured story uses main music")
	player.show_main()
	await settle()
	await capture("main")
	player.show_settings()
	await settle()
	check(player.page == "settings", "Settings page opens")
	await capture("settings")
	check(player.audio.current_music_id == "music_main", "Menu music keeps playing across pages")
	var sliders: Array = []
	for child in player.canvas.get_children():
		if child is HSlider: sliders.append(child)
	check(sliders.size() == 2, "Settings exposes music and sfx sliders")
	if sliders.size() == 2:
		sliders[0].value = 0.35
		sliders[1].value = 0.5
		await process_frame
		check(is_equal_approx(player.audio_settings.music_volume, 0.35), "Music slider updates settings")
		check(is_equal_approx(player.audio_settings.sfx_volume, 0.5), "SFX slider updates settings")
		var music_bus := AudioServer.get_bus_index("Music")
		check(is_equal_approx(AudioServer.get_bus_volume_db(music_bus), linear_to_db(0.35)), "Music slider drives the bus")
		check(not AudioServer.is_bus_mute(music_bus), "Music bus unmuted")
		sliders[1].value = 0.0
		await process_frame
		check(AudioServer.is_bus_mute(AudioServer.get_bus_index("SFX")), "Zero SFX volume mutes the bus")
		sliders[1].value = 0.5
		await process_frame
	check(FileAccess.file_exists(AUDIO), "Settings persist to disk")
	var saved = Settings.new()
	check(saved.load_settings(AUDIO) == OK, "Persisted settings reload")
	check(is_equal_approx(saved.music_volume, 0.35) and is_equal_approx(saved.sfx_volume, 0.5), "Persisted values round-trip")

	player.queue_free()
	await settle()
	var reloaded = Player.instantiate()
	reloaded.save_path = SAVE
	reloaded.audio_settings_path = AUDIO
	root.add_child(reloaded)
	await settle()
	check(is_equal_approx(reloaded.audio_settings.music_volume, 0.35), "Volume survives a restart")
	reloaded.queue_free()
	await settle()
