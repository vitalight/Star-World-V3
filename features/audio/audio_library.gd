@tool
class_name AudioLibrary
extends Resource
## Explicit cue references keep sounds discoverable in both the editor and exports.
const ID_PATTERN := "^(music|sfx)_[a-z0-9_]+$"
const BUSES := ["Music", "SFX"]

@export var cues: Array[AudioCue] = []

func find(id: String) -> AudioCue:
	for cue in cues:
		if cue and cue.id == id: return cue
	return null

func ids() -> PackedStringArray:
	var result := PackedStringArray()
	for cue in cues:
		if cue and not cue.id.is_empty(): result.append(cue.id)
	return result

## Structural problems only: a null stream is a valid placeholder while assets are pending.
func errors() -> PackedStringArray:
	var issues := PackedStringArray()
	var regex := RegEx.new()
	regex.compile(ID_PATTERN)
	var seen := {}
	for index in cues.size():
		var cue: AudioCue = cues[index]
		if cue == null:
			issues.append("Cue %d: 为空" % index)
			continue
		if cue.id.is_empty():
			issues.append("Cue %d: 缺少 id" % index)
		elif regex.search(cue.id) == null:
			issues.append("Cue %s: id 需为 music_* 或 sfx_* 的小写标识" % cue.id)
		if not cue.id.is_empty() and seen.has(cue.id):
			issues.append("Cue %s: id 重复" % cue.id)
		seen[cue.id] = true
		if cue.bus not in BUSES:
			issues.append("Cue %s: 未知总线 %s" % [cue.id, cue.bus])
		elif cue.id.begins_with("music_") and cue.bus != "Music":
			issues.append("Cue %s: 音乐需使用 Music 总线" % cue.id)
		elif cue.id.begins_with("sfx_") and cue.bus != "SFX":
			issues.append("Cue %s: 音效需使用 SFX 总线" % cue.id)
		if cue.pitch_variance < 0.0 or cue.pitch_variance > 0.5:
			issues.append("Cue %s: 音高浮动需在 0.0..0.5" % cue.id)
	return issues
