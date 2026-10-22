@tool
extends Resource
## Earliest first spawn; shifted forward if needed to complete the route warning.
@export var time := 1.0
@export var count := 3
@export var interval := 2.0
@export var enemy := "soldier"
@export var route := "upper"
@export var number := 1

func configuration() -> Dictionary:
	return {"time": time, "count": count, "interval": interval, "enemy": enemy, "route": route, "number": number}
