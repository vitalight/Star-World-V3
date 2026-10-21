extends ScrollContainer
## Shared developer-only breadcrumb. Navigation is supplied by the workspace.
var segments: PackedStringArray
var row: HBoxContainer

func _init() -> void:
	horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	custom_minimum_size.y = 46
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	add_child(row)

func configure(path: PackedStringArray, hub_callback: Callable = Callable()) -> void:
	segments = path
	for child in row.get_children():
		row.remove_child(child)
		child.queue_free()
	for index in path.size():
		if index > 0:
			add_text("/")
		if path[index] == "Developer Hub" and hub_callback.is_valid():
			var link := Button.new()
			link.text = path[index]
			link.flat = true
			# Breadcrumb height stays compact when a workspace supplies padded buttons.
			link.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
			var hover := StyleBoxFlat.new()
			hover.bg_color = Color("203140")
			hover.set_corner_radius_all(6)
			link.add_theme_stylebox_override("hover", hover)
			link.add_theme_stylebox_override("pressed", hover)
			link.add_theme_font_size_override("font_size", 24)
			link.pressed.connect(hub_callback)
			row.add_child(link)
		else:
			add_text(path[index])

func add_text(value: String) -> void:
	var text := Label.new()
	text.text = value
	text.add_theme_font_size_override("font_size", 24)
	row.add_child(text)
