@tool
class_name ActorDefinition
extends Resource
## Authoring entry point; Battle consumes only stats.configuration().
const UnitSpec = preload("res://features/battle/unit_spec.gd")
const Appearance = preload("res://features/actor_view/actor_appearance.gd")
@export var stats: UnitSpec
@export var appearance: Appearance
@export var identity := ""
@export var profession := ""
