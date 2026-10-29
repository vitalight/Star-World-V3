@tool
extends RefCounted
## Lossless CSV editing: unmodified rows retain their original raw bytes.
var path := ""
var header := PackedStringArray()
var rows: Array[Dictionary] = []
var original := ""
var original_bytes := PackedByteArray()
var raw_header := ""
var error := ""

func load_table(file_path: String) -> bool:
	path = file_path
	rows.clear()
	error = ""
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		error = "无法读取 " + path
		return false
	original_bytes = file.get_buffer(file.get_length())
	original = original_bytes.get_string_from_utf8()
	file.seek(0)
	header = file.get_csv_line()
	var header_end := file.get_position()
	file.seek(0)
	raw_header = file.get_buffer(header_end).get_string_from_utf8()
	file.seek(header_end)
	if not header.is_empty():
		header[0] = header[0].trim_prefix("\uFEFF")
	if header.is_empty():
		error = "CSV 表头为空：" + path
		return false
	while file.get_position() < file.get_length():
		var start := file.get_position()
		var fields := file.get_csv_line()
		var finish := file.get_position()
		file.seek(start)
		var raw := file.get_buffer(finish - start).get_string_from_utf8()
		file.seek(finish)
		if fields.size() == 1 and fields[0].strip_edges().is_empty():
			continue
		if fields.size() != header.size():
			error = "CSV 列数不匹配：" + path
			return false
		var values := {}
		for index in header.size():
			values[header[index]] = fields[index]
		rows.append({"values": values, "raw": raw, "dirty": false})
	return true

func set_value(row: Dictionary, key: String, value: String) -> void:
	if row.values.get(key, "") != value:
		row.values[key] = value
		row.dirty = true

func changed() -> bool:
	for row in rows:
		if row.dirty:
			return true
	return false

func serialize() -> String:
	var lines := []
	for value in header:
		lines.append(_escape(value))
	var output := raw_header
	if not output.ends_with("\n"): output += "\n"
	for row in rows:
		if not row.dirty:
			output += row.raw
			if not row.raw.ends_with("\n"):
				output += "\n"
			continue
		lines.clear()
		for key in header:
			lines.append(_escape(str(row.values.get(key, ""))))
		output += ",".join(lines) + "\n"
	return output

func _escape(value: String) -> String:
	if value.contains(",") or value.contains("\"") or value.contains("\n") or value.contains("\r"):
		return "\"" + value.replace("\"", "\"\"") + "\""
	return value

func conflicts() -> bool:
	return not FileAccess.file_exists(path) or FileAccess.get_file_as_bytes(path) != original_bytes

func save() -> String:
	if conflicts():
		return "源文件已被外部修改：" + path
	var failure: String = preload("res://devtools/balance_editor/safe_write.gd").replace(path, serialize().to_utf8_buffer())
	if not failure.is_empty():
		return failure
	if not load_table(path):
		return error
	return ""
