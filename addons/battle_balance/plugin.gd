@tool
extends EditorPlugin

var panel: Control

func _enter_tree() -> void:
	panel = preload("res://devtools/balance_editor/editor_panel.gd").new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	EditorInterface.get_editor_main_screen().add_child(panel)
	panel.play_requested.connect(_play_level)
	_make_visible(false)


func _exit_tree() -> void:
	if panel: panel.queue_free()

func _has_main_screen() -> bool:
	return true

func _make_visible(visible: bool) -> void:
	if panel: panel.visible = visible

func _get_plugin_name() -> String:
	return "战斗数值"

func _get_plugin_icon() -> Texture2D:
	return EditorInterface.get_editor_theme().get_icon("Node", "EditorIcons")

func _get_unsaved_status(_for_scene: String) -> String:
	if panel and (panel.model.has_changes() or not panel.invalid.is_empty()):
		return "战斗数值编辑器有未保存的修改"
	return ""

func _save_external_data() -> void:
	if panel and panel.model.has_changes():
		panel._save()

func _play_level(level_id: String) -> void:
	var dir := "res://temp/balance_editor"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
	var request := FileAccess.open(dir + "/play_request.json", FileAccess.WRITE)
	if request == null:
		panel.status.text = "无法创建试玩请求。"
		return
	request.store_string(JSON.stringify({"level": level_id, "time": Time.get_unix_time_from_system()}))
	request.close()
	EditorInterface.play_custom_scene("res://devtools/game_test/game_workspace.tscn")
