extends RefCounted
## Versioned volume settings, stored separately from campaign progress.

const VERSION := 1
const DEFAULT_VOLUME := 0.8
var music_volume := DEFAULT_VOLUME
var sfx_volume := DEFAULT_VOLUME
var _file := ConfigFile.new()

func load_settings(path: String) -> Error:
	_file = ConfigFile.new()
	music_volume = DEFAULT_VOLUME
	sfx_volume = DEFAULT_VOLUME
	var result := _file.load(path)
	if result != OK: return result
	if _file.get_value("audio", "version", 0) != VERSION: return ERR_FILE_UNRECOGNIZED
	music_volume = _read_volume("music")
	sfx_volume = _read_volume("sfx")
	return OK

func save(path: String) -> Error:
	_file.set_value("audio", "version", VERSION)
	_file.set_value("audio", "music", music_volume)
	_file.set_value("audio", "sfx", sfx_volume)
	return _file.save(path)

func _read_volume(key: String) -> float:
	var value = _file.get_value("audio", key, DEFAULT_VOLUME)
	if not (value is float or value is int): return DEFAULT_VOLUME
	return clampf(float(value), 0.0, 1.0)
