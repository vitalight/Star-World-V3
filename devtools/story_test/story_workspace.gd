extends Control
const UI = preload("res://devtools/ui/workspace_style.gd")
const Session = preload("res://features/story/story_session.gd")
const StoryView = preload("res://features/story/story_view.gd")
const SAMPLE = preload("res://devtools/story_test/sample_story.tres")
const BACKGROUNDS = {
	"winter": preload("res://Human/StarterContent/story/story-01.png"),
	"garden": preload("res://Human/StarterContent/story/story-02.png")}
const SCOUT = preload("res://content/data/character_001.tres")
const GUARD = preload("res://content/data/character_003.tres")
const ACCENT = Color("dfc49b")
var session = Session.new()
var stage: Control
var status: Label
var speaker: Label
var dialogue: Label
var choices: VBoxContainer
var continue_button: Button
var history: Label
var breadcrumb: Control
var toolbar: HFlowContainer
var auto_button: Button
var modal: Control
var modal_panel: PanelContainer
var modal_title: Label
var auto_play := false
var _elapsed := 0.0
var source_picker: OptionButton
var source_catalog = preload("res://game/content/content_catalog.gd").new()

func _ready() -> void:
	theme = UI.make_theme(ACCENT)
	stage = StoryView.new()
	stage.configure(BACKGROUNDS, {"scout": SCOUT.appearance.poses[0], "guard": GUARD.appearance.poses[0]})
	add_child(stage)
	stage.advance_requested.connect(_advance)
	stage.choice_requested.connect(_choose)
	speaker = stage.speaker
	dialogue = stage.dialogue
	choices = stage.choices
	continue_button = stage.continue_button
	breadcrumb = UI.PATH.new()
	add_child(breadcrumb)
	breadcrumb.configure(PackedStringArray(["Star World", "Developer Hub", "Story Test"]),
		func(): get_tree().change_scene_to_file("res://devtools/hub/developer_hub.tscn"))
	toolbar = HFlowContainer.new()
	toolbar.alignment = FlowContainer.ALIGNMENT_END
	add_child(toolbar)
	auto_button = _button(toolbar, "自动 ▶", _toggle_auto)
	auto_button.toggle_mode = true
	_button(toolbar, "跳过 ▸", _skip)
	_button(toolbar, "记录", _show_overlay.bind(false))
	_button(toolbar, "重播剧情", _restart)
	_button(toolbar, "调试", _show_overlay.bind(true))
	source_picker = OptionButton.new()
	source_picker.add_item("开发样例")
	source_picker.set_item_metadata(0, [])
	source_catalog.reload()
	for id in source_catalog.levels:
		for kind in ["before", "after"]:
			source_picker.add_item(source_catalog.levels[id].name + (" · 战前" if kind == "before" else " · 战后"))
			source_picker.set_item_metadata(source_picker.item_count - 1, [id, kind])
	source_picker.item_selected.connect(_load_source)
	toolbar.add_child(source_picker)
	_button(toolbar, "重新加载", func(): _load_source(source_picker.selected))
	_build_overlay()
	resized.connect(_layout)
	_layout()
	var errors: PackedStringArray = session.load_story(SAMPLE)
	if not errors.is_empty():
		status.text = "剧情配置错误：\n" + "\n".join(errors)
		modal.show()
		continue_button.disabled = true
		return
	_refresh()

func _button(parent: Node, text: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_font_size_override("font_size", 16)
	for key in ["normal", "hover", "pressed"]:
		button.add_theme_stylebox_override(key, UI.box(Color(0.025, 0.03, 0.04, 0.68),
			Color(0.7, 0.68, 0.63, 0.35), 10, 3))
	button.pressed.connect(action)
	parent.add_child(button)
	return button

func _load_source(index: int) -> void:
	_set_auto(false)
	modal.hide()
	var source: Array = source_picker.get_item_metadata(index)
	var script: Resource = SAMPLE
	var errors := PackedStringArray()
	if source.is_empty():
		stage.configure(BACKGROUNDS, {"scout": SCOUT.appearance.poses[0], "guard": GUARD.appearance.poses[0]})
	else:
		source_catalog.reload()
		errors = source_catalog.diagnostics(source[0])
		if errors.is_empty():
			var textures: Dictionary = source_catalog.story_textures()
			stage.configure(textures.backgrounds, textures.actors)
			script = source_catalog.story(source_catalog.levels[source[0]][source[1]])
	if errors.is_empty(): errors = session.load_story(script)
	if not errors.is_empty():
		status.text = "剧情配置错误：\n" + "\n".join(errors)
		modal.show(); return
	_refresh()

func _build_overlay() -> void:
	modal = Control.new()
	modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(modal)
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.7)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal.add_child(shade)
	modal_panel = PanelContainer.new()
	modal_panel.add_theme_stylebox_override("panel", UI.box(Color("111820"), UI.LINE, 24))
	modal.add_child(modal_panel)
	var column := VBoxContainer.new()
	modal_panel.add_child(column)
	var top := HBoxContainer.new()
	column.add_child(top)
	modal_title = UI.text(top, "对话记录", 24, ACCENT)
	modal_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_button(top, "返回剧情", func(): modal.hide())
	status = UI.text(column, "", 16, ACCENT)
	var body := UI.scroll_body(column)
	history = UI.text(body, "", 17, UI.INK)
	modal.hide()

func _layout() -> void:
	if not is_node_ready():
		return
	breadcrumb.position = Vector2(24, 16)
	breadcrumb.size = Vector2(minf(580, size.x - 48), 40)
	var narrow := size.x < 1120
	toolbar.position = Vector2(24 if narrow else size.x - 560, 64 if narrow else 16)
	toolbar.size = Vector2(size.x - 48 if narrow else 536, 50)
	modal_panel.position = Vector2(maxf(20, (size.x - 1000) * 0.5), size.y * 0.12)
	modal_panel.size = Vector2(minf(1000, size.x - 40), size.y * 0.76)

func _advance() -> void:
	if modal.visible:
		return
	if session.advance():
		_refresh()

func _choose(index: int) -> void:
	if session.choose(index):
		_refresh()

func _restart() -> void:
	_set_auto(false)
	modal.hide()
	session.restart()
	_refresh()

func _set_auto(enabled: bool) -> void:
	auto_play = enabled
	_elapsed = 0.0
	auto_button.set_pressed_no_signal(enabled)
	auto_button.text = "自动 ▌▌" if enabled else "自动 ▶"

func _toggle_auto() -> void:
	var state: Dictionary = session.snapshot()
	_set_auto(not auto_play and state.get("type") == "line")

func _process(delta: float) -> void:
	if not auto_play or modal.visible:
		return
	_elapsed += delta
	var state: Dictionary = session.snapshot()
	var delay := maxf(2.5, str(state.get("text", "")).length() * 0.085)
	if _elapsed >= delay:
		_advance()

func _skip() -> void:
	_set_auto(false)
	var visited := {}
	for step in 128:
		var state: Dictionary = session.snapshot()
		if state.get("type") != "line" or visited.has(state.get("id")):
			break
		visited[state.id] = true
		if not session.advance():
			break
	_refresh()

func _show_overlay(debug: bool) -> void:
	modal_title.text = "剧情调试" if debug else "对话记录"
	status.visible = debug
	modal.show()
	_layout()

func _refresh() -> void:
	var state: Dictionary = session.snapshot()
	if state.is_empty():
		return
	_elapsed = 0.0
	if state.type != "line":
		_set_auto(false)
	stage.show_snapshot(state)
	status.text = "%s\n节点：%s  ·  %s  ·  已读 %d 段\n背景：%s  ·  出场：%s" % [state.title, state.id,
		{"line": "对话", "choice": "等待选择", "end": "剧情结束"}[state.type], state.history.size(),
		state.get("background", "无"), ", ".join(state.get("actors", []))]
	var lines := PackedStringArray()
	for item in state.history:
		lines.append("%s：%s" % [item.speaker, item.text])
		if item.has("selected"):
			lines.append("  → " + item.selected)
	history.text = "\n\n".join(lines)

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") and not event.is_echo():
		_advance()
		get_viewport().set_input_as_handled()
