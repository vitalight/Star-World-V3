@tool
class_name ActorLibrary
extends Resource
## Explicit references keep resources discoverable in both the editor and exports.
const Actor = preload("res://features/content_definitions/actor_definition.gd")
const Skill = preload("res://features/content_definitions/skill_definition.gd")
@export var skills: Array[Skill] = []
@export var characters: Array[Actor] = []
@export var enemies: Array[Actor] = []
