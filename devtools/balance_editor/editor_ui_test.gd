extends SceneTree
const BalancePanel = preload("res://devtools/balance_editor/editor_panel.gd")
const ROOT := "res://temp/balance_ui_fixture/"
var failures := 0
var panel: Control
var played := ""

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(ROOT + "data"))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(ROOT + "campaign"))
	for file in DirAccess.get_files_at("res://content/data"):
		if not file.ends_with(".tres"): continue
		var text := FileAccess.get_file_as_string("res://content/data/" + file).replace("res://content/data/", ROOT + "data/")
		var output := FileAccess.open(ROOT + "data/" + file, FileAccess.WRITE)
		output.store_string(text)
		output.close()
	for file in ["levels.csv", "waves.csv"]:
		var output := FileAccess.open(ROOT + "campaign/" + file, FileAccess.WRITE)
		output.store_buffer(FileAccess.get_file_as_bytes("res://content/campaign/" + file))
		output.close()
	panel = BalancePanel.new()
	panel.model.data_dir = ROOT + "data/"
	panel.model.campaign_dir = ROOT + "campaign/"
	get_root().add_child.call_deferred(panel)
	call_deferred("_run")

func find_field(node: Node, field: String) -> LineEdit:
	for child in node.get_children():
		if child is HBoxContainer and child.get_child_count() >= 2:
			var label = child.get_child(0)
			var input = child.get_child(1)
			if label is Label and input is LineEdit and input.name == field:
				return input
		var found := find_field(child, field)
		if found: return found
	return null

func set_field(field: String, value: String) -> void:
	var edit := find_field(panel.body, field)
	check(edit != null, "field found: " + field)
	if edit:
		edit.text = value
		edit.text_changed.emit(value)

func select_id(id: String) -> void:
	var index: int = panel.entries.find(id)
	check(index >= 0, "entry found: " + id)
	if index >= 0: panel._select_item(index)

func _run() -> void:
	await process_frame
	await process_frame
	check(panel.selected == "scene_0101B", "first level selected")
	var preview: TextureRect = panel.body.get_node_or_null("LevelPreview")
	check(preview != null and preview.texture != null and preview.texture.resource_path == "res://content/scenes/scene_0101B/level_preview.png", "selected level preview shown")
	select_id("scene_0102B")
	preview = panel.body.get_node_or_null("LevelPreview")
	check(preview != null and preview.texture != null and preview.texture.resource_path == "res://content/scenes/scene_0102B/level_preview.png", "switching levels updates preview")
	select_id("scene_0101B")
	set_field("life", "6")
	check(panel.model.levels.rows[1].values.life == "6", "level input updates draft")
	panel._select_category(1)
	select_id("character_011")
	var portrait := panel.body.get_node_or_null("Portrait") as TextureRect
	check(portrait != null and portrait.texture == panel.model.actors["character_011"].appearance.portrait, "character portrait shown")
	set_field("attack", "101")
	check(panel.model.actors["character_011"].stats.attack == 101, "character input updates correct field")
	set_field("range_cells", "0,0;1,0;2,0")
	check(panel.model.actors["character_011"].stats.range_cells.size() == 3, "range input updates cells")
	var grid: GridContainer = panel.body.find_child("RangeGrid", true, false)
	var range_button: Button = grid.get_node("Cell_3_0")
	check(not range_button.button_pressed, "range grid reflects coordinate input")
	range_button.pressed.emit()
	check(panel.model.actors["character_011"].stats.range_cells.has(Vector2i(3, 0)), "grid adds a range cell")
	check(find_field(panel.body, "range_cells").text.contains("3,0"), "grid updates coordinate input")
	range_button = grid.get_node("Cell_3_0")
	range_button.pressed.emit()
	check(not panel.model.actors["character_011"].stats.range_cells.has(Vector2i(3, 0)), "grid removes a range cell")
	var pan: Button = panel.body.find_child("RangePan_1_0", true, false)
	pan.pressed.emit()
	check(grid.has_node("Cell_6_0") and not grid.has_node("Cell_-3_0"), "range view can move to further cells")
	set_field("range_cells", "")
	check(not panel.invalid.is_empty(), "empty range blocks saving")
	set_field("range_cells", "0,0;1,0;2,0")
	check(panel.invalid.is_empty(), "valid range clears error")
	await process_frame
	var scroll := panel.body.get_parent() as ScrollContainer
	scroll.ensure_control_visible(grid)
	await process_frame
	await RenderingServer.frame_post_draw
	get_root().get_texture().get_image().save_png(ProjectSettings.globalize_path("res://temp/balance_range_editor.png"))
	panel._select_category(2)
	select_id("skill_001")
	var icon := panel.body.get_node_or_null("SkillIcon") as TextureRect
	check(icon != null and icon.texture != null and icon.texture == panel.model.skills["skill_001"].icon, "skill icon shown")
	select_id("skill_002")
	icon = panel.body.get_node_or_null("SkillIcon") as TextureRect
	check(icon != null and icon.texture != null and icon.texture == panel.model.skills["skill_002"].icon, "switching skill updates icon")
	select_id("skill_001")
	set_field("multiplier", "1.9")
	check(is_equal_approx(panel.model.skills["skill_001"].multiplier, 1.9), "skill input updates correct field")
	panel._select_category(3)
	select_id("enemy_001")
	portrait = panel.body.get_node_or_null("Portrait") as TextureRect
	check(portrait != null and portrait.texture == panel.model.actors["enemy_001"].appearance.portrait, "enemy portrait shown")
	set_field("max_hp", "310")
	check(panel.model.actors["enemy_001"].stats.max_hp == 310, "enemy input updates correct field")
	panel._select_category(0)
	select_id("scene_0101B")
	set_field("count", "4")
	check(panel.model.waves.rows[0].values.count == "4", "wave input updates correct row")
	check(find_field(panel.body, "number") == null, "wave number is not editable")
	var original_number: String = panel.model.waves.rows[0].values.number
	var original_count: int = panel.model.waves.rows.size()
	panel._add_wave()
	check(panel.model.waves.rows.size() == original_count + 1, "wave can be added")
	var added: Dictionary = panel.model.waves.rows.back()
	var remove: Button
	for node in panel.body.find_children("*", "Button", true, false):
		if node.text == "删除此组波次": remove = node
	check(remove != null, "wave delete button is available")
	if remove: remove.pressed.emit()
	check(panel.model.waves.rows.size() == original_count and not panel.model.waves.rows.has(added), "wave can be deleted")
	panel.play_requested.connect(func(id): played = id)
	panel._play()
	check(played == "scene_0101B", "save and play emits selected level")
	check(not panel.model.has_changes(), "save clears dirty state")
	check(panel.model.waves.rows[0].values.count == "4" and panel.model.waves.rows[0].values.number == original_number, "wave edits save without changing existing number")
	check(panel.model.actors["character_011"].stats.attack == 101, "character survives reload")
	check(panel.model.actors["character_011"].stats.range_cells == [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)], "visual range edits survive save and reload")
	await process_frame
	await process_frame
	get_root().get_texture().get_image().save_png(ProjectSettings.globalize_path("res://temp/balance_editor_ui.png"))
	print("BALANCE UI: ", failures, " failures")
	quit(1 if failures else 0)
