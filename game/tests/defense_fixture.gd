extends RefCounted
## Reproducible integration scenario; all actions use public battle commands.
static func deployments() -> Array:
	return [["guard", Vector2i(3, 1), 2], ["tank", Vector2i(3, 4), 2],
		["sniper", Vector2i(5, 2), 2], ["caster", Vector2i(4, 3), 2], ["medic", Vector2i(4, 2), 2]]

static func scheduled() -> Array:
	return [{"at": 3.0, "method": "activate_skill", "args": [1]},
		{"at": 12.0, "method": "retreat", "args": [4]},
		{"at": 18.0, "method": "deploy", "args": ["caster", Vector2i(4, 3), 2]}]
