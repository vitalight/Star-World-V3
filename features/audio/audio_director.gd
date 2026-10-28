extends Node
## Owns the Music/SFX buses and players. The product flow creates one instance and injects a library.
## Missing cues and cues without a stream stay silent by design, so content can arrive later.
const MUSIC_BUS := "Music"
const SFX_BUS := "SFX"
const MUSIC_PLAYERS := 2
const SFX_PLAYERS := 12
const SILENCE_DB := -80.0

var library: AudioLibrary
var settings
var current_music_id := ""
var music_players: Array[AudioStreamPlayer] = []
var sfx_players: Array[AudioStreamPlayer] = []
var _active_music := 0
var _sfx_cursor := 0
var _fade_time := 0.0
var _fade_duration := 0.0
var _fade_in: AudioStreamPlayer
var _fade_out: AudioStreamPlayer
var _fade_out_start := SILENCE_DB
var _fade_in_end := SILENCE_DB
var _rng := RandomNumberGenerator.new()
var _initialized := false

func _ready() -> void:
	_initialize()

## Idempotent: tests and late callers may use the director before it enters the tree.
func _initialize() -> void:
	if _initialized: return
	_initialized = true
	_rng.randomize()
	_ensure_bus(MUSIC_BUS)
	_ensure_bus(SFX_BUS)
	for index in MUSIC_PLAYERS:
		music_players.append(_make_player(MUSIC_BUS))
	for index in SFX_PLAYERS:
		sfx_players.append(_make_player(SFX_BUS))
	if settings: apply_settings(settings)

func set_library(value: AudioLibrary) -> void:
	library = value

func apply_settings(value) -> void:
	settings = value
	if settings == null: return
	_apply_bus(MUSIC_BUS, settings.music_volume)
	_apply_bus(SFX_BUS, settings.sfx_volume)

func play_music(id: String, fade := 1.0) -> bool:
	_initialize()
	var cue := _cue(id, MUSIC_BUS)
	if cue == null:
		current_music_id = ""
		_stop_active(fade)
		return false
	# Repeated page calls keep the current track running instead of restarting it.
	if id == current_music_id and _active_player().playing:
		return true
	current_music_id = id
	if cue.stream == null:
		current_music_id = ""
		_stop_active(fade)
		return false
	_finish_fade()
	var outgoing := _active_player()
	_active_music = 1 - _active_music
	var incoming := _active_player()
	incoming.stream = cue.stream
	incoming.pitch_scale = 1.0
	incoming.volume_db = cue.volume_db if fade <= 0.0 else SILENCE_DB
	incoming.play()
	if fade <= 0.0:
		outgoing.stop()
		return true
	_start_fade(incoming, outgoing, fade, cue.volume_db)
	return true

func stop_music(fade := 0.3) -> void:
	current_music_id = ""
	_stop_active(fade)

func play_sfx(id: String) -> bool:
	_initialize()
	var cue := _cue(id, SFX_BUS)
	if cue == null or cue.stream == null: return false
	var player := _idle_sfx_player()
	player.stream = cue.stream
	player.volume_db = cue.volume_db
	player.pitch_scale = clampf(1.0 + _rng.randf_range(-cue.pitch_variance, cue.pitch_variance), 0.1, 4.0)
	player.play(cue.start_offset)
	return true

func _process(delta: float) -> void:
	if _fade_duration <= 0.0: return
	_fade_time = minf(_fade_time + delta, _fade_duration)
	var weight := _fade_time / _fade_duration
	if is_instance_valid(_fade_in): _fade_in.volume_db = lerpf(SILENCE_DB, _fade_in_end, weight)
	if is_instance_valid(_fade_out): _fade_out.volume_db = lerpf(_fade_out_start, SILENCE_DB, weight)
	if _fade_time >= _fade_duration: _finish_fade()

func _stop_active(fade: float) -> void:
	if music_players.is_empty(): return
	_finish_fade()
	var player := _active_player()
	if not player.playing: return
	if fade <= 0.0:
		player.stop()
		return
	_start_fade(null, player, fade, SILENCE_DB)

func _start_fade(incoming: AudioStreamPlayer, outgoing: AudioStreamPlayer, duration: float, in_end_db: float) -> void:
	_fade_in = incoming
	_fade_out = outgoing
	_fade_duration = maxf(duration, 0.0001)
	_fade_time = 0.0
	_fade_in_end = in_end_db
	_fade_out_start = outgoing.volume_db if is_instance_valid(outgoing) and outgoing.playing else SILENCE_DB

func _finish_fade() -> void:
	if is_instance_valid(_fade_in): _fade_in.volume_db = _fade_in_end
	if is_instance_valid(_fade_out): _fade_out.stop()
	_fade_in = null
	_fade_out = null
	_fade_duration = 0.0
	_fade_time = 0.0

func _active_player() -> AudioStreamPlayer:
	return music_players[_active_music]

func _idle_sfx_player() -> AudioStreamPlayer:
	var count := sfx_players.size()
	for offset in count:
		var index := (_sfx_cursor + offset) % count
		if not sfx_players[index].playing:
			_sfx_cursor = (index + 1) % count
			return sfx_players[index]
	var index := _sfx_cursor
	_sfx_cursor = (_sfx_cursor + 1) % count
	return sfx_players[index]

func _cue(id: String, bus_name: String) -> AudioCue:
	if library == null: return null
	var cue := library.find(id)
	if cue == null or cue.bus != bus_name: return null
	return cue

func _make_player(bus_name: String) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.bus = bus_name
	player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(player)
	return player

func _ensure_bus(bus_name: String) -> int:
	var index := AudioServer.get_bus_index(bus_name)
	if index != -1: return index
	index = AudioServer.bus_count
	AudioServer.add_bus(index)
	AudioServer.set_bus_name(index, bus_name)
	AudioServer.set_bus_send(index, "Master")
	return index

func _apply_bus(bus_name: String, volume: float) -> void:
	var index := _ensure_bus(bus_name)
	if volume <= 0.0001:
		AudioServer.set_bus_mute(index, true)
	else:
		AudioServer.set_bus_mute(index, false)
		AudioServer.set_bus_volume_db(index, linear_to_db(clampf(volume, 0.0, 1.0)))
