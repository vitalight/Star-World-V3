extends RefCounted
## Shared visual language for developer workspaces; never used by game features.
const PATH = preload("res://devtools/ui/workspace_path.gd")
const INK = Color("edf2f7")
const MUTED = Color("99a9bb")
const SURFACE = Color("182431")
const LINE = Color("2c3b4c")

static func box(background: Color, border: Color = LINE, padding: int = 12, radius: int = 10) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(radius)
	style.content_margin_left = padding
	style.content_margin_right = padding
	style.content_margin_top = padding
	style.content_margin_bottom = padding
	return style

static func make_theme(accent: Color) -> Theme:
	var theme := Theme.new()
	theme.default_font_size = 16
	theme.set_color("font_color", "Label", INK)
	theme.set_constant("separation", "VBoxContainer", 10)
	theme.set_constant("separation", "HBoxContainer", 10)
	theme.set_constant("h_separation", "HFlowContainer", 12)
	theme.set_constant("v_separation", "HFlowContainer", 12)
	theme.set_stylebox("panel", "PanelContainer", box(SURFACE, LINE, 8))
	theme.set_stylebox("normal", "Button", box(Color("203040"), LINE, 12, 8))
	theme.set_stylebox("hover", "Button", box(Color("293e4e"), accent.darkened(0.3), 12, 8))
	theme.set_stylebox("pressed", "Button", box(Color("243c48"), accent, 12, 8))
	theme.set_stylebox("disabled", "Button", box(Color("17222e"), Color("263442"), 12, 8))
	var focus := box(Color.TRANSPARENT, accent, 0, 8)
	focus.set_border_width_all(2)
	theme.set_stylebox("focus", "Button", focus)
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		theme.set_color(state, "Button", INK)
	theme.set_color("font_disabled_color", "Button", Color("61758a"))
	theme.set_stylebox("panel", "TabContainer", box(Color("131f2b"), LINE, 12))
	theme.set_stylebox("tab_selected", "TabContainer", box(Color("243b43"), accent, 14, 8))
	theme.set_stylebox("tab_unselected", "TabContainer", box(Color("182431"), LINE, 14, 8))
	theme.set_stylebox("tab_hovered", "TabContainer", box(Color("20333f"), accent.darkened(0.4), 14, 8))
	theme.set_color("font_selected_color", "TabContainer", INK)
	theme.set_color("font_unselected_color", "TabContainer", MUTED)
	for type in ["VScrollBar", "HScrollBar"]:
		theme.set_stylebox("scroll", type, box(Color("101923"), Color("101923"), 4, 4))
		theme.set_stylebox("grabber", type, box(Color("43576b"), Color("43576b"), 4, 4))
		theme.set_stylebox("grabber_highlight", type, box(accent.darkened(0.3), accent.darkened(0.3), 4, 4))
		theme.set_stylebox("grabber_pressed", type, box(accent, accent, 4, 4))
	return theme

static func shell(root: Control, name: String, accent: Color) -> VBoxContainer:
	root.theme = make_theme(accent)
	var background := ColorRect.new()
	background.color = Color("101923")
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(background)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for edge in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + edge, 24)
	root.add_child(margin)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 14)
	margin.add_child(layout)
	var breadcrumb := PATH.new()
	layout.add_child(breadcrumb)
	breadcrumb.configure(PackedStringArray(["Star World", "Developer Hub", name]),
		func(): root.get_tree().change_scene_to_file("res://devtools/hub/developer_hub.tscn"))
	layout.add_child(divider())
	return layout

static func text(parent: Node, value: String, size: int = 16, color: Color = MUTED) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(label)
	return label

static func heading(parent: Node, title: String, description: String, accent: Color) -> void:
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	parent.add_child(column)
	text(column, title, 28, accent)
	text(column, description)

static func scroll_body(parent: Node) -> VBoxContainer:
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(scroll)
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 14)
	scroll.add_child(column)
	return column

static func divider() -> ColorRect:
	var line := ColorRect.new()
	line.color = LINE
	line.custom_minimum_size.y = 1
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return line
