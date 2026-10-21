extends PanelContainer
## Static readout configured externally; never computes battle outcomes.
@export var caption: String = "ART COMPOSITION / MOCK DATA"
@export var readout: String = "LIFE 20     WAVE 1 / 3     COST 55     SPEED 1×"

func _ready() -> void:
	var box := VBoxContainer.new()
	add_child(box)
	for value in [caption, readout]:
		var label := Label.new()
		label.text = value
		label.add_theme_font_size_override("font_size", 19)
		box.add_child(label)
