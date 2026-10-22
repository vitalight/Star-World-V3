extends RefCounted
## One consumer drains simulation events; copies are broadcast to observers by the scene.
const Actor = preload("res://features/actor_view/actor_view_3d.gd")
const RouteGuide = preload("res://features/battlefield_view/route_guide.gd")
const Effect = preload("res://features/effects/effect_view_3d.gd")
var actors := {}
var departing: Array = []
var effects: Array = []
var world: Node3D
var field: Node3D
var appearances: Dictionary
var configuration: Dictionary
var effect_texture: Texture2D
var combatants := {}
var projectiles := {}
var route_guides := {}
const PROJECTILE = preload("res://content/effects/effect_001/projectile.tres")
const IMPACT = preload("res://content/effects/effect_001/impact.tres")
const HEALING = preload("res://content/effects/effect_001/healing.tres")
const BOOST = preload("res://content/effects/effect_001/boost.tres")

func _init(parent: Node3D, terrain: Node3D, catalog: Dictionary, config: Dictionary) -> void:
	world = parent; field = terrain; appearances = catalog; configuration = config
	effect_texture = preload("res://content/effects/effect_001/texture.tres")

func clear() -> void:
	for actor in actors.values() + departing + effects + route_guides.values():
		if is_instance_valid(actor): actor.free()
	actors.clear(); departing.clear(); effects.clear()
	combatants.clear(); projectiles.clear(); route_guides.clear()

func position(at: Vector2, flying := false) -> Vector3:
	return Vector3(at.x, field.surface_height(Vector2i(at.round())) + (0.8 if flying else 0.045), at.y)

func sync(state: Dictionary, events: Array, delta: float) -> void:
	_sync_route_guides(state)
	for actor in actors.values() + departing:
		if is_instance_valid(actor) and not actor.is_queued_for_deletion(): actor.advance_visual(delta)
	for effect in effects:
		if is_instance_valid(effect) and not effect.is_queued_for_deletion():
			if effect.kind == "projectile" and actors.has(effect.get_meta("target", -1)):
				effect.destination = actors[effect.get_meta("target")].position + body_offset()
			effect.advance_visual(delta)
	departing = departing.filter(func(a): return is_instance_valid(a) and not a.is_queued_for_deletion())
	effects = effects.filter(func(a): return is_instance_valid(a) and not a.is_queued_for_deletion())
	# Spawn/deploy descriptors also cover actors that enter and die within one sync.
	for event in events:
		if event.type == "spawn": combatants[event.source] = configuration.enemies[event.template]
		elif event.type == "deploy": combatants[event.source] = configuration.roster[event.roster_id]
	var present := {}
	for unit in state.units + state.enemies:
		combatants[unit.id] = unit
		var enemy: bool = unit.has("template")
		var key: String = unit.template if enemy else unit.roster_id
		var spec: Dictionary = configuration.enemies[key] if enemy else configuration.roster[key]
		var appearance = appearances[spec.content_id] if spec.has("content_id") else appearances[key]
		if not actors.has(unit.id):
			var actor = Actor.new()
			actor.appearance = appearance
			actor.texture = appearance.poses[0]
			actor.height = appearance.height
			world.add_child(actor)
			actor.position = position(unit.position, unit.get("flying", false))
			if enemy: actor.set_meta("facing", initial_enemy_facing(unit))
			actors[unit.id] = actor
		var actor = actors[unit.id]
		if enemy:
			var movement: Vector2 = unit.position - Vector2(actor.position.x, actor.position.z)
			unit = unit.duplicate(true)
			if not movement.is_zero_approx():
				actor.set_meta("facing", facing_for(movement))
			unit.facing = actor.get_meta("facing", 0)
		actor.position = position(unit.position, unit.get("flying", false))
		if state.phase in ["victory", "defeat"]:
			unit = unit.duplicate(true)
			unit.skill_hint_allowed = false
		actor.apply_state(unit, enemy)
		present[unit.id] = true
	for event in events:
		if event.type == "attack_start":
			var source: Dictionary = combatants.get(event.source, {})
			var healing: bool = event.friendly and source.get("role", "") == "healer"
			if healing: continue
			var ranged: bool = source.get("role", "") == "ranged" if event.friendly else source.get("ranged", false)
			var from := event_position(event.source, event.from)
			var to := event_position(event.target, event.to)
			var effect = spawn_effect(PROJECTILE if ranged else effect_texture, "projectile" if ranged else "slash", 0.9 if ranged else 1.3)
			if ranged:
				finish_projectile(event.source)
				effect.set_meta("target", event.target)
				effect.play_projectile(from, to, source.get("windup", 0.2))
				projectiles[event.source] = effect
			else: effect.play_slash(from, to)
		elif event.type in ["damage", "heal"]:
			finish_projectile(event.source)
			if actors.has(event.target): actors[event.target].hit(event.type == "heal")
			var color := Color.WHITE if not event.get("enhanced", false) else Color("cbbaff")
			pulse(event_position(event.target, event.to), color, HEALING if event.type == "heal" else IMPACT, "heal" if event.type == "heal" else "impact")
		elif event.type == "miss": finish_projectile(event.source)
		elif event.type == "skill_start" and actors.has(event.source):
			pulse(actors[event.source].position + body_offset(), Color.WHITE, BOOST, "skill")
	for id in actors.keys():
		if not present.has(id):
			actors[id].depart()
			departing.append(actors[id])
			actors.erase(id)
	if state.phase in ["victory", "defeat"]:
		for view in departing + effects:
			if is_instance_valid(view): view.queue_free()
		departing.clear(); effects.clear(); projectiles.clear()

func facing_for(direction: Vector2) -> int:
	return (0 if direction.x >= 0 else 2) if absf(direction.x) > absf(direction.y) else (1 if direction.y >= 0 else 3)

func initial_enemy_facing(unit: Dictionary) -> int:
	var route: Array = configuration.routes.get(unit.get("route", ""), [])
	var remaining: float = unit.get("distance", 0.0)
	for index in range(1, route.size()):
		var direction := Vector2(route[index]) - Vector2(route[index - 1])
		if remaining < direction.length() or index == route.size() - 1:
			return facing_for(direction)
		remaining -= direction.length()
	return unit.get("facing", 0)

func _sync_route_guides(state: Dictionary) -> void:
	var active := {}
	if state.phase not in ["victory", "defeat"]:
		for warning in state.get("route_warnings", []):
			active[warning.id] = true
			if not route_guides.has(warning.id):
				var guide = RouteGuide.new()
				world.add_child(guide)
				guide.configure(configuration.routes[warning.route], Callable(field, "surface_height"))
				route_guides[warning.id] = guide
			route_guides[warning.id].set_progress((state.time - warning.start) / warning.duration)
	for id in route_guides.keys():
		if not active.has(id):
			route_guides[id].free()
			route_guides.erase(id)

func event_position(id: int, at: Vector2) -> Vector3:
	return position(at, combatants.get(id, {}).get("flying", false)) + body_offset()

func body_offset() -> Vector3:
	var camera := world.get_viewport().get_camera_3d()
	return (camera.global_basis.y if camera else Vector3.UP) * 0.55

func finish_projectile(source: int) -> void:
	var projectile = projectiles.get(source)
	if is_instance_valid(projectile) and not projectile.is_queued_for_deletion(): projectile.queue_free()
	projectiles.erase(source)

func spawn_effect(texture: Texture2D, kind: String, width: float):
	var effect = Effect.new()
	effect.texture = texture
	effect.width = width
	effect.kind = kind
	world.add_child(effect)
	effects.append(effect)
	return effect

func pulse(at: Vector3, color: Color, texture: Texture2D = IMPACT, kind := "impact") -> void:
	var effect = spawn_effect(texture, kind, 1.15)
	effect.position = at
	effect.play_once(color, 0.28)
