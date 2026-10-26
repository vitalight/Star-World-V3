extends RefCounted
## Battle events -> sound cues. The simulation stays free of audio vocabulary.

const CUE_IDS := [
	"sfx_deploy", "sfx_retreat", "sfx_spawn", "sfx_notify", "sfx_cost_gain",
	"sfx_skill_start", "sfx_skill_end", "sfx_attack", "sfx_hit", "sfx_hurt",
	"sfx_heal", "sfx_miss", "sfx_block", "sfx_enemy_death", "sfx_unit_death",
	"sfx_escape", "sfx_victory", "sfx_defeat",
]

var director

func _init(audio = null) -> void:
	director = audio

func sync(_state: Dictionary, events: Array) -> void:
	if director == null: return
	# One cue per event batch keeps clustered hits from stacking into noise.
	var played := {}
	for event in events:
		var cue_id := cue_for(event)
		if cue_id.is_empty() or played.has(cue_id): continue
		played[cue_id] = true
		director.play_sfx(cue_id)

static func cue_for(event: Dictionary) -> String:
	match str(event.get("type", "")):
		"deploy": return "sfx_deploy"
		"retreat": return "sfx_retreat"
		"spawn": return "sfx_spawn"
		"route_warning": return "sfx_notify"
		"cost_gain": return "sfx_cost_gain"
		"skill_start": return "sfx_skill_start"
		"skill_end": return "sfx_skill_end"
		"attack_start": return "sfx_attack"
		"damage": return "sfx_hit" if event.get("friendly", false) == true else "sfx_hurt"
		"heal": return "sfx_heal"
		"miss": return "sfx_miss"
		"block": return "sfx_block"
		"death": return "sfx_enemy_death" if event.get("side", "") == "enemy" else "sfx_unit_death"
		"escape": return "sfx_escape"
		"finished":
			return "sfx_victory" if event.get("phase", "") == "victory" else "sfx_defeat"
	return ""
