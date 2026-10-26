extends SceneTree
const Cue = preload("res://features/audio/audio_cue.gd")
const Library = preload("res://features/audio/audio_library.gd")
const Settings = preload("res://features/audio/audio_settings.gd")
const Director = preload("res://features/audio/audio_director.gd")
const SAVE_PATH := "user://audio_test_settings.cfg"
var checks := 0
var failures := 0

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)

func _initialize() -> void:
	var library = _library()
	_check_library(library)
	_check_settings()
	var director = Director.new()
	root.add_child(director)
	await process_frame
	_check_director(director, library)
	director.free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	print("Audio rules: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

func _stream() -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 22050
	stream.data = PackedByteArray(); stream.data.resize(2204)
	return stream

func _any_playing(players: Array) -> bool:
	for player in players:
		if player.playing: return true
	return false

func _cue(id: String, bus := "SFX", stream: AudioStream = null) -> AudioCue:
	var cue = Cue.new()
	cue.id = id; cue.bus = bus; cue.stream = stream
	return cue

func _library() -> AudioLibrary:
	var library = Library.new()
	library.cues.assign([
		_cue("music_main", "Music", _stream()),
		_cue("music_battle", "Music", _stream()),
		_cue("music_pending", "Music"),
		_cue("sfx_hit", "SFX", _stream()),
		_cue("sfx_pending", "SFX"),
	])  # A stream-less cue proves the silent path used by pending content.
	return library

func _check_library(library: AudioLibrary) -> void:
	check(library.find("music_main") != null, "Known cue resolves")
	check(library.find("missing") == null, "Unknown cue returns null")
	check(library.ids().size() == 5, "Ids report every named cue")
	check(library.errors().is_empty(), "Valid library has no errors")

	var broken = Library.new()
	broken.cues.assign([null, _cue("", "SFX"), _cue("Music_Main", "Music"), _cue("sfx_hit", "SFX"),
		_cue("sfx_hit", "SFX"), _cue("music_bad", "SFX"), _cue("sfx_bad", "Music"), _cue("sfx_pitch", "SFX")])
	broken.cues[7].pitch_variance = 0.9
	var issues: PackedStringArray = broken.errors()
	check(issues.size() == 7, "Structural problems are reported: %d" % issues.size())
	check(library.find("sfx_pending").stream == null and library.errors().is_empty(), "Stream-less cues are valid")

func _check_settings() -> void:
	var settings = Settings.new()
	check(settings.music_volume == Settings.DEFAULT_VOLUME, "Defaults start at 0.8")
	check(settings.load_settings(SAVE_PATH) != OK, "Missing file reports an error")
	check(settings.music_volume == Settings.DEFAULT_VOLUME, "Missing file keeps defaults")

	settings.music_volume = 0.25; settings.sfx_volume = 1.0
	check(settings.save(SAVE_PATH) == OK, "Settings save")
	var loaded = Settings.new()
	check(loaded.load_settings(SAVE_PATH) == OK, "Settings reload")
	check(is_equal_approx(loaded.music_volume, 0.25) and is_equal_approx(loaded.sfx_volume, 1.0), "Values round-trip")

	loaded.music_volume = 2.0
	loaded.save(SAVE_PATH)
	var clamped = Settings.new()
	clamped.load_settings(SAVE_PATH)
	check(is_equal_approx(clamped.music_volume, 1.0), "Out-of-range values clamp on load")

	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_string("not a config")
	file.close()
	var corrupt = Settings.new()
	check(corrupt.load_settings(SAVE_PATH) != OK, "Corrupt file reports an error")
	check(corrupt.music_volume == Settings.DEFAULT_VOLUME, "Corrupt file keeps defaults")

func _check_director(director: Node, library: AudioLibrary) -> void:
	director.set_library(library)
	check(AudioServer.get_bus_index("Music") != -1 and AudioServer.get_bus_index("SFX") != -1, "Buses are created")
	check(director.music_players.size() == Director.MUSIC_PLAYERS and director.sfx_players.size() == Director.SFX_PLAYERS, "Players are created")
	check(director.play_music("music_main", 0.0), "Music with a stream starts")
	check(director.current_music_id == "music_main", "Current music is observable")
	check(director.play_music("music_main", 0.0), "Repeating the current track is a no-op")
	check(director.play_music("music_battle", 0.0) and director.current_music_id == "music_battle", "Music switches")
	check(not director.play_music("music_pending", 0.0), "Stream-less music stays silent")
	check(director.current_music_id == "", "Stream-less music clears the current id")
	check(not director.play_music("music_missing", 0.0), "Unknown music stays silent")
	director.play_music("music_main", 0.0)
	director.stop_music(0.0)
	check(director.current_music_id == "" and not _any_playing(director.music_players), "Stop clears the active track")

	check(director.play_sfx("sfx_hit"), "SFX with a stream plays")
	check(not director.play_sfx("sfx_pending"), "Stream-less SFX stays silent")
	check(not director.play_sfx("sfx_missing"), "Unknown SFX stays silent")
	for index in Director.SFX_PLAYERS + 2:
		check(director.play_sfx("sfx_hit"), "SFX pool reuses voices under load")

	var settings = Settings.new()
	settings.music_volume = 0.0; settings.sfx_volume = 0.5
	director.apply_settings(settings)
	check(AudioServer.is_bus_mute(AudioServer.get_bus_index("Music")), "Zero volume mutes the music bus")
	check(not AudioServer.is_bus_mute(AudioServer.get_bus_index("SFX")), "Nonzero volume unmutes the sfx bus")
