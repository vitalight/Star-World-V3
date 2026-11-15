extends RefCounted

const GameCatalog = preload("res://game/content/content_catalog.gd")
const Presentation = preload("res://game/adapters/battle_presentation.gd")
const ActorView = preload("res://features/actor_view/actor_view_3d.gd")
const PENDING_HEROES = [
	["前哥", "res://content/characters/character_018/appearance.tres"],
	["冰冰", "res://content/characters/character_019/appearance.tres"],
]
const PENDING_ENEMIES = [
	["晶甲巨兽", "brute"],
	["雷电巨兽", "beast"],
]

static func raw_frames(key: String, action: String) -> Array[Texture2D]:
	var atlas := load("res://Human/StarterContent/enemy_animation_v1/%s-%s-sheet.png" % [key, action]) as Texture2D
	var result: Array[Texture2D] = []
	for index in 4:
		var texture := AtlasTexture.new()
		texture.atlas = atlas
		var left := floori(atlas.get_width() * (index % 2) / 2.0)
		var right := floori(atlas.get_width() * (index % 2 + 1) / 2.0)
		var top := floori(atlas.get_height() * (index / 2) / 2.0)
		var bottom := floori(atlas.get_height() * (index / 2 + 1) / 2.0)
		texture.region = Rect2(left, top, right - left, bottom - top)
		texture.filter_clip = true
		result.append(texture)
	return result

static func characters(catalog = null, filter_kind := "") -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if catalog == null:
		catalog = GameCatalog.new()
		catalog.reload()
	var appearances: Dictionary = catalog.all_appearances()
	var names := {}
	for kind in ["character", "enemy"]:
		if not filter_kind.is_empty() and filter_kind != kind: continue
		var collection: Dictionary = catalog.characters if kind == "character" else catalog.enemies
		for id in collection:
			var appearance = appearances[id]
			var name: String = collection[id].stats.name
			names[name] = true
			var attack: Array = appearance.attack_frames()
			if attack.is_empty(): attack = appearance.poses
			var movement: Array = [appearance.poses[0]] if kind == "enemy" else appearance.move_frames()
			result.append({"id": id, "kind": kind, "name": name, "attack": attack, "move": movement, "procedural_walk": kind == "enemy"})
	if filter_kind in ["", "character"]:
		for item in PENDING_HEROES:
			if names.has(item[0]): continue
			var appearance = load(item[1])
			result.append({"id": "", "kind": "character", "name": item[0], "attack": appearance.attack_frames(), "move": []})
	if filter_kind in ["", "enemy"]:
		for item in PENDING_ENEMIES:
			if names.has(item[0]): continue
			var attack := raw_frames(item[1], "attack")
			result.append({"id": "", "kind": "enemy", "name": item[0], "attack": attack, "move": [attack[0]], "procedural_walk": true})
	return result

static func effects() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for item in [["刀光", Presentation.SLASH], ["子弹", Presentation.PROJECTILE], ["受击", Presentation.IMPACT], ["治疗", Presentation.HEALING], ["强化", Presentation.BOOST]]:
		result.append({"name": item[0], "texture": item[1]})
	return result

static func frames(textures: Array, action: String) -> SpriteFrames:
	var result := SpriteFrames.new()
	result.set_animation_speed(&"default", 1.0)
	for index in textures.size():
		var ends: Array = ActorView.ATTACK_FRAME_ENDS
		var frame := index % ends.size()
		var duration: float = ActorView.WALK_PERIOD / textures.size() if action == "move" else ends[frame] - (ends[frame - 1] if frame > 0 else 0.0)
		result.add_frame(&"default", textures[index], duration)
	return result

static func skills(catalog = null) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if catalog == null:
		catalog = GameCatalog.new()
		catalog.reload()
	var icons: Dictionary = catalog.all_skill_icons()
	for id in icons:
		var actor: Dictionary = catalog.characters[id].stats
		result.append({"name": "%s · %s" % [actor.name, actor.skill.name], "texture": icons[id]})
	return result
