extends RefCounted

static func create() -> Dictionary:
	return {
		"path": [Vector2(60, 260), Vector2(270, 260), Vector2(270, 130), Vector2(570, 130), Vector2(570, 360), Vector2(850, 360)],
		"slots": [Vector2(180, 180), Vector2(380, 210), Vector2(480, 290), Vector2(680, 280)],
		"life": 3, "count": 8, "spawn_interval": 1.6, "enemy_hp": 60,
		"enemy_speed": 65.0, "damage": 20, "attack_range": 160.0, "attack_interval": 0.65
	}
