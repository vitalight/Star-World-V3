@tool
extends RefCounted

static func replace(path: String, bytes: PackedByteArray) -> String:
	var absolute := ProjectSettings.globalize_path(path)
	var parent := ProjectSettings.globalize_path("res://temp/balance_editor")
	var mkdir_error := DirAccess.make_dir_recursive_absolute(parent)
	if mkdir_error != OK: return "无法创建临时目录：" + error_string(mkdir_error)
	var token := str(Time.get_ticks_usec())
	var stage := parent.path_join("." + absolute.get_file() + "." + token + ".stage")
	var backup := parent.path_join("." + absolute.get_file() + "." + token + ".backup")
	var output := FileAccess.open(stage, FileAccess.WRITE)
	if output == null:
		return "无法创建临时文件：" + path
	output.store_buffer(bytes)
	var write_error := output.get_error()
	output.close()
	if write_error != OK:
		DirAccess.remove_absolute(stage)
		return "无法写入临时文件：" + path
	var result := DirAccess.rename_absolute(absolute, backup)
	if result != OK:
		DirAccess.remove_absolute(stage)
		return "无法备份源文件：" + path
	result = DirAccess.rename_absolute(stage, absolute)
	if result != OK:
		var rollback := DirAccess.rename_absolute(backup, absolute)
		DirAccess.remove_absolute(stage)
		return "无法替换文件：%s；恢复结果 %s" % [path, error_string(rollback)]
	DirAccess.remove_absolute(backup)
	return ""
