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
	set_field("life", "6")
	check(panel.model.levels.rows[1].values.life == "6", "level input updates draft")
	panel._select_category(1)
	select_id("character_011")
	set_field("attack", "101")
	check(panel.model.actors["character_011"].stats.attack == 101, "character input updates correct field")
	set_field("range_cells", "0,0;1,0;2,0")
	check(panel.model.actors["character_011"].stats.range_cells.size() == 3, "range input updates cells")
	panel._select_category(2)
	select_id("skill_001")
	set_field("multiplier", "1.9")
	check(is_equal_approx(panel.model.skills["skill_001"].multiplier, 1.9), "skill input updates correct field")
	panel._select_category(3)
	select_id("enemy_001")
	set_field("max_hp", "310")
	check(panel.model.actors["enemy_001"].stats.max_hp == 310, "enemy input updates correct field")
	panel._select_category(0)
	select_id("scene_0101B")
	set_field("count", "4")
	check(panel.model.waves.rows[0].values.count == "4", "wave input updates correct row")
	panel.play_requested.connect(func(id): played = id)
	panel._play()
	check(played == "scene_0101B", "save and play emits selected level")
	check(not panel.model.has_changes(), "save clears dirty state")
	check(panel.model.actors["character_011"].stats.attack == 101, "character survives reload")
	await process_frame
	await process_frame
	get_root().get_texture().get_image().save_png(ProjectSettings.globalize_path("res://temp/balance_editor_ui.png"))
	print("BALANCE UI: ", failures, " failures")
	quit(1 if failures else 0)
