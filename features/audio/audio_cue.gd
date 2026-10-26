@tool
class_name AudioCue
extends Resource
## One playable sound. Mix settings live here; looping comes from the stream's import options.

@export var id := ""
@export_enum("Music", "SFX") var bus := "SFX"
@export var stream: AudioStream
@export_range(-40.0, 12.0, 0.1) var volume_db := 0.0
@export_range(0.0, 0.5, 0.01) var pitch_variance := 0.0
