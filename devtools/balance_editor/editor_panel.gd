@tool
extends VBoxContainer

signal play_requested(level_id: String)
const Model = preload("res://devtools/balance_editor/editor_model.gd")
const LABELS := {
	"life":"基地生命", "initial_cost":"初始费用", "cost_cap":"费用上限", "cost_regen":"每秒回复费用", "deploy_limit":"部署上限", "defend_duration":"防守时间（秒）", "roster_mode":"编队模式", "fixed_roster":"固定编队（ID 用 | 分隔）",
	"time":"出场时间（秒）", "count":"数量", "interval":"攻击／出场间隔（秒）", "enemy":"敌人 ID", "route":"路线 ID", "number":"显示波次",
	"range_cells":"攻击范围（x,y；分号分隔）", "description":"技能说明", "max_hp":"生命", "attack":"攻击", "defense":"防御", "resistance":"法术抗性", "damage_type":"伤害类型", "windup":"攻击前摇", "role":"职业", "cost":"部署费用", "redeploy_time":"再部署时间", "block":"阻挡数", "anti_air":"可以对空", "passive":"普通攻击被动", "speed":"移动速度", "ranged":"远程攻击", "attack_range":"攻击距离", "flying":"飞行", "leak_damage":"漏怪伤害",
	"recovery":"充能方式", "required":"所需技力", "initial_sp":"初始技力", "duration":"持续时间", "multiplier":"攻击倍率", "defense_multiplier":"防御倍率", "interval_multiplier":"攻击间隔倍率", "cost_gain":"回复费用", "trigger":"释放方式", "forward_range":"向前延伸范围", "hit_count":"攻击次数", "heal_damage_reduction":"治疗减伤比例", "heal_buff_duration":"治疗效果持续时间"
}
const UNIT_FIELDS := ["max_hp", "attack", "defense", "resistance", "damage_type", "interval", "windup"]
const OPERATOR_FIELDS := ["role", "cost", "redeploy_time", "block", "anti_air", "passive"]
const ENEMY_FIELDS := ["speed", "ranged", "attack_range", "flying", "leak_damage"]
const SKILL_FIELDS := ["recovery", "required", "initial_sp", "duration", "multiplier", "defense_multiplier", "interval_multiplier", "cost_gain", "trigger", "forward_range", "hit_count", "heal_damage_reduction", "heal_buff_duration"]
const LEVEL_FIELDS := ["life", "initial_cost", "cost_cap", "cost_regen", "deploy_limit", "defend_duration", "roster_mode", "fixed_roster"]
const WAVE_FIELDS := ["time", "count", "interval", "enemy", "route", "number"]
const CHOICES := {"damage_type":["physical","arts","true"], "role":["melee","ranged","healer"], "recovery":["auto","attack","hit"], "trigger":["manual","automatic"], "roster_mode":["fixed","player"]}

var model = Model.new()
var category := 0
var selected := ""
var selected_level := ""
var entries: Array = []
var category_picker: OptionButton
var item_picker: OptionButton
var status: Label
var body: VBoxContainer
var invalid := {}
var refresh_guard := false

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_theme_constant_override("separation", 0)
	if not model.load_all():
		var failure := Label.new()
		failure.text = "\n".join(model.errors)
		add_child(failure)
		return
	var header := PanelContainer.new()
	header.add_theme_stylebox_override("panel", _box(Color("172533"), Color("344a5a"), 20))
	add_child(header)
	var header_content := VBoxContainer.new()
	header_content.add_theme_constant_override("separation", 12)
	header.add_child(header_content)
	var title_row := HBoxContainer.new()
	header_content.add_child(title_row)
	var title_column := VBoxContainer.new()
	title_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_column.add_theme_constant_override("separation", 3)
	title_row.add_child(title_column)
	var eyebrow := Label.new()
	eyebrow.text = "STAR WORLD  /  内容配置"
	eyebrow.add_theme_color_override("font_color", Color("7cc8bd"))
	eyebrow.add_theme_font_size_override("font_size", 12)
	title_column.add_child(eyebrow)
	var title := Label.new()
	title.text = "战斗数值编辑器"
	title.add_theme_color_override("font_color", Color("eef5f6"))
	title.add_theme_font_size_override("font_size", 24)
	title_column.add_child(title)
	var save := Button.new()
	save.text = "保存所有修改"
	_style_button(save, false)
	save.pressed.connect(_save)
	title_row.add_child(save)
	var play := Button.new()
	play.text = "保存并试玩关卡  →"
	_style_button(play, true)
	play.pressed.connect(_play)
	title_row.add_child(play)
	var toolbar := HBoxContainer.new()
	toolbar.add_theme_constant_override("separation", 10)
	header_content.add_child(toolbar)
	var category_label := Label.new()
	category_label.text = "配置分类"
	category_label.add_theme_color_override("font_color", Color("aabdc7"))
	toolbar.add_child(category_label)
	category_picker = OptionButton.new()
	category_picker.custom_minimum_size.x = 150
	for title_text in ["关卡强度", "角色强度", "技能强度", "怪物强度"]:
		category_picker.add_item(title_text)
	toolbar.add_child(category_picker)
	category_picker.item_selected.connect(_select_category)
	var object_label := Label.new()
	object_label.text = "编辑对象"
	object_label.add_theme_color_override("font_color", Color("aabdc7"))
	toolbar.add_child(object_label)
	item_picker = OptionButton.new()
	item_picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	toolbar.add_child(item_picker)
	item_picker.item_selected.connect(_select_item)
	status = Label.new()
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status.add_theme_font_size_override("font_size", 13)
	status.add_theme_color_override("font_color", Color("91b6ad"))
	header_content.add_child(status)
	var background := PanelContainer.new()
	background.size_flags_vertical = Control.SIZE_EXPAND_FILL
	background.add_theme_stylebox_override("panel", _box(Color("101a24"), Color("101a24"), 18))
	add_child(background)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	background.add_child(scroll)
	body = VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 16)
	scroll.add_child(body)
	body.resized.connect(_fit_grids)
	_select_category(0)

func _select_category(index: int) -> void:
	category = index
	category_picker.select(index)
	_populate_items()

func _populate_items(preferred := "") -> void:
	refresh_guard = true
	item_picker.clear()
	entries.clear()
	if category == 0:
		for row in model.levels.rows:
			if row.values.type == "battle":
				entries.append(row.values.id)
				item_picker.add_item(row.values.name)
	else:
		var source: Dictionary = model.skills if category == 2 else model.actors
		var keys := source.keys()
		keys.sort()
		for id in keys:
			if category == 1 and not str(id).begins_with("character_"): continue
			if category == 3 and not str(id).begins_with("enemy_"): continue
			var display: String = source[id].display_name if category == 2 else source[id].stats.display_name
			entries.append(id)
			item_picker.add_item("%s · %s" % [display, id])
	var chosen := entries.find(preferred)
	if chosen < 0: chosen = 0
	if not entries.is_empty():
		item_picker.select(chosen)
	refresh_guard = false
	if not entries.is_empty(): _select_item(chosen)

func _select_item(index: int) -> void:
	if refresh_guard or index < 0 or index >= entries.size(): return
	selected = str(entries[index])
	if category == 0: selected_level = selected
	_rebuild()

func _rebuild() -> void:
	for child in body.get_children():
		body.remove_child(child)
		child.queue_free()
	if category == 0: _level_form()
	else: _resource_form()
	_update_status()

func _box(background: Color, border: Color, padding := 16) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(10)
	style.content_margin_left = padding
	style.content_margin_right = padding
	style.content_margin_top = padding
	style.content_margin_bottom = padding
	return style

func _style_button(button: Button, primary: bool) -> void:
	var background := Color("286c68") if primary else Color("263a49")
	var border := Color("4aa497") if primary else Color("496071")
	button.add_theme_stylebox_override("normal", _box(background, border, 10))
	button.add_theme_stylebox_override("hover", _box(background.lightened(0.16), border.lightened(0.16), 10))
	button.add_theme_stylebox_override("pressed", _box(background.darkened(0.14), border, 10))
	button.add_theme_color_override("font_color", Color("edf5f5"))
	button.custom_minimum_size.y = 40

func _heading(title: String, description := "") -> void:
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 4)
	body.add_child(column)
	var label := Label.new()
	label.text = title
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_color_override("font_color", Color("ecf3f5"))
	column.add_child(label)
	if not description.is_empty():
		var subtitle := Label.new()
		subtitle.text = description
		subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		subtitle.add_theme_color_override("font_color", Color("9bafba"))
		subtitle.add_theme_font_size_override("font_size", 13)
		column.add_child(subtitle)

func _card(title: String, description := "") -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _box(Color("1b2a37"), Color("334958"), 18))
	body.add_child(panel)
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 12)
	panel.add_child(column)
	var heading := Label.new()
	heading.text = title
	heading.add_theme_font_size_override("font_size", 18)
	heading.add_theme_color_override("font_color", Color("d7f0e9"))
	column.add_child(heading)
	if not description.is_empty():
		var detail := Label.new()
		detail.text = description
		detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		detail.add_theme_font_size_override("font_size", 13)
		detail.add_theme_color_override("font_color", Color("9db1bb"))
		column.add_child(detail)
	return column

func _grid(parent: Control) -> GridContainer:
	var grid := GridContainer.new()
	grid.columns = 2 if body.size.x >= 900 else 1
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 24)
	grid.add_theme_constant_override("v_separation", 10)
	grid.add_to_group("balance_editor_grids")
	parent.add_child(grid)
	return grid

func _fit_grids() -> void:
	if not is_inside_tree(): return
	for grid in get_tree().get_nodes_in_group("balance_editor_grids"):
		if is_ancestor_of(grid): grid.columns = 2 if body.size.x >= 900 else 1

func _line(parent: Control, field: String) -> HBoxContainer:
	var line := HBoxContainer.new()
	line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line.add_theme_constant_override("separation", 10)
	parent.add_child(line)
	var label := Label.new()
	label.text = str(LABELS.get(field, field))
	if field == "interval": label.text = "出怪间隔（秒）" if category == 0 else "攻击间隔（秒）"
	label.tooltip_text = field
	label.custom_minimum_size.x = 150
	label.add_theme_color_override("font_color", Color("c2d0d5"))
	line.add_child(label)
	return line

func _text_field(parent: Control, field: String, value: String, callback: Callable) -> void:
	var line := _line(parent, field)
	var input := LineEdit.new()
	input.name = field
	input.text = value
	input.custom_minimum_size.y = 34
	input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	input.text_changed.connect(callback)
	line.add_child(input)

func _choice_field(parent: Control, field: String, value: String, options: Array, callback: Callable) -> void:
	var line := _line(parent, field)
	var picker := OptionButton.new()
	picker.name = field
	picker.custom_minimum_size.y = 34
	picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var translations := {
		"damage_type":{"physical":"物理", "arts":"法术", "true":"真实"},
		"role":{"melee":"近战", "ranged":"远程", "healer":"医疗"},
		"recovery":{"auto":"自动回复", "attack":"攻击回复", "hit":"受击回复"},
		"trigger":{"manual":"手动释放", "automatic":"自动释放"},
		"roster_mode":{"fixed":"固定编队", "player":"玩家编队"}
	}
	for option in options:
		var text := str(option)
		if translations.has(field): text = str(translations[field].get(option, option))
		if field == "enemy" and model.actors.has(option):
			text = "%s  ·  %s" % [model.actors[option].stats.display_name, option]
		picker.add_item(text)
	var index := options.find(value)
	if index >= 0: picker.select(index)
	picker.item_selected.connect(func(i): callback.call(str(options[i])))
	line.add_child(picker)

func _level_form() -> void:
	var row: Dictionary = {}
	for candidate in model.levels.rows:
		if candidate.values.id == selected: row = candidate; break
	if row.is_empty(): return
	_heading(str(row.values.name), "调整关卡容错、部署节奏和出怪安排。修改会保留在草稿中，保存后可试玩。")
	var groups := [
		{"title":"基地与防守", "description":"决定漏怪容错和胜利条件。", "fields":["life", "defend_duration"]},
		{"title":"部署资源", "description":"控制开局费用、费用回复和同时上场人数。", "fields":["initial_cost", "cost_cap", "cost_regen", "deploy_limit"]},
		{"title":"参战编队", "description":"固定编队的角色 ID 使用 | 分隔。", "fields":["roster_mode", "fixed_roster"]}
	]
	for group in groups:
		var fields := _grid(_card(group.title, group.description))
		for field in group.fields:
			var callback := func(value):
				model.levels.set_value(row, field, value)
				model.table_dirty = true
				_update_status()
			if CHOICES.has(field):
				_choice_field(fields, field, str(row.values[field]), CHOICES[field], callback)
			else:
				_text_field(fields, field, str(row.values[field]), callback)
	_heading("出怪波次", "按出场时间安排敌人；每张卡片代表一组敌人。")
	var scene = load(str(row.values.map))
	var route_names: Array = []
	if scene is PackedScene:
		var map = scene.instantiate()
		route_names = map.routes().keys()
		map.free()
	var enemy_ids: Array = []
	for id in model.actors:
		if str(id).begins_with("enemy_"): enemy_ids.append(id)
	enemy_ids.sort()
	for wave in model.waves.rows:
		if wave.values.level != selected: continue
		var box := _card("第 %s 波  ·  %s" % [wave.values.number, wave.values.id])
		var fields := _grid(box)
		for field in WAVE_FIELDS:
			var callback := func(value):
				model.waves.set_value(wave, field, value)
				model.table_dirty = true
				_update_status()
			if field == "enemy": _choice_field(fields, field, str(wave.values[field]), enemy_ids, callback)
			elif field == "route": _choice_field(fields, field, str(wave.values[field]), route_names, callback)
			else: _text_field(fields, field, str(wave.values[field]), callback)
		var remove := Button.new()
		remove.text = "删除此组波次"
		remove.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		remove.pressed.connect(func():
			model.waves.rows.erase(wave)
			model.table_dirty = true
			_rebuild())
		box.add_child(remove)
	var add := Button.new()
	add.text = "+  新增波次"
	add.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_style_button(add, false)
	add.pressed.connect(_add_wave)
	body.add_child(add)

func _add_wave() -> void:
	var max_id := int(Time.get_unix_time_from_system() * 1000.0)
	for row in model.waves.rows:
		var value := str(row.values.id)
		if value.begins_with("wave_"): max_id = maxi(max_id, int(value.trim_prefix("wave_")))
	var row: Dictionary = {}
	for candidate in model.levels.rows:
		if candidate.values.id == selected: row = candidate
	var map = load(str(row.values.map)).instantiate()
	var routes: Array = map.routes().keys()
	map.free()
	var enemies: Array = []
	for id in model.actors:
		if str(id).begins_with("enemy_"): enemies.append(id)
	enemies.sort()
	if routes.is_empty() or enemies.is_empty():
		status.text = "地图或敌人列表为空，不能添加波次。"
		return
	var values := {"id":"wave_%03d" % (max_id + 1), "level":selected, "time":"0", "count":"1", "interval":"1", "enemy":enemies[0], "route":routes[0], "number":"1"}
	model.waves.rows.append({"values":values, "raw":"", "dirty":true})
	model.table_dirty = true
	_rebuild()

func _resource_form() -> void:
	var owner: Resource = model.skills[selected] if category == 2 else model.actors[selected]
	var object: Resource = owner if category == 2 else owner.stats
	var display: String = owner.display_name if category == 2 else object.display_name
	_heading(display + "  ·  " + selected, "此资源会影响所有引用它的内容。 " + _references(selected))
	var groups: Array
	if category == 2:
		groups = [
			{"title":"触发与充能", "description":"控制技能如何积累技力、何时释放。", "fields":["recovery","required","initial_sp","trigger","duration"]},
			{"title":"技能效果", "description":"调整增益倍率、攻击次数与费用回复。", "fields":["multiplier","defense_multiplier","interval_multiplier","cost_gain","forward_range","hit_count"]},
			{"title":"治疗附加效果", "description":"治疗技能可附加减伤和持续时间。", "fields":["heal_damage_reduction","heal_buff_duration"]}
		]
	elif category == 1:
		groups = [
			{"title":"基础属性", "description":"角色的生命、伤害与防护能力。", "fields":["max_hp","attack","defense","resistance","damage_type"]},
			{"title":"攻击节奏", "description":"控制攻击间隔和前摇。", "fields":["interval","windup"]},
			{"title":"部署与职责", "description":"费用、阻挡、再部署和对空能力。", "fields":OPERATOR_FIELDS}
		]
	else:
		groups = [
			{"title":"基础属性", "description":"怪物的生命、伤害与防护能力。", "fields":["max_hp","attack","defense","resistance","damage_type"]},
			{"title":"攻击节奏", "description":"控制攻击间隔和前摇。", "fields":["interval","windup"]},
			{"title":"行动与突破", "description":"移动、远程攻击、飞行与漏怪伤害。", "fields":ENEMY_FIELDS}
		]
	for group in groups:
		var fields := _grid(_card(group.title, group.description))
		for field in group.fields: _resource_field(fields, owner, object, field)
	if category == 1:
		var range_card := _card("攻击范围", "以角色朝右为基准，每个坐标用分号分隔，例如 0,0;1,0。")
		_range_field(range_card, owner, object)
		var skill_note := Label.new()
		skill_note.text = "关联技能：" + (str(object.skill_spec.display_name) if object.skill_spec else "无") + "；可在技能强度页调整。"
		skill_note.add_theme_color_override("font_color", Color("9db1bb"))
		range_card.add_child(skill_note)
	if category == 2:
		var description_card := _card("技能说明", "数值变化不会自动修改说明，请同步检查玩家看到的文字。")
		_description_field(description_card, owner)

func _resource_field(parent: Control, owner: Resource, object: Resource, field: String) -> void:
	var path: String = owner.resource_path
	var key := path + "::" + field
	var value = object.get(field)
	var callback := func(text: String):
		if typeof(value) in [TYPE_FLOAT, TYPE_INT]:
			var valid := text.is_valid_int() if typeof(value) == TYPE_INT else text.is_valid_float()
			if not valid or (typeof(value) == TYPE_FLOAT and not is_finite(text.to_float())):
				invalid[key] = true
				_update_status()
				return
			invalid.erase(key)
			object.set(field, int(text) if typeof(value) == TYPE_INT else float(text))
		else:
			object.set(field, text)
		model.mark_resource(path)
		_update_status()
	if typeof(value) == TYPE_BOOL:
		var line := _line(parent, field)
		var check := CheckBox.new()
		check.button_pressed = value
		check.toggled.connect(func(enabled):
			object.set(field, enabled)
			model.mark_resource(path)
			_update_status())
		line.add_child(check)
	elif CHOICES.has(field):
		_choice_field(parent, field, str(value), CHOICES[field], callback)
	else:
		_text_field(parent, field, str(value), callback)

func _description_field(parent: Control, skill: Resource) -> void:
	var line := _line(parent, "description")
	var edit := TextEdit.new()
	edit.text = skill.description
	edit.custom_minimum_size.y = 80
	edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	edit.text_changed.connect(func():
		skill.description = edit.text
		model.mark_resource(skill.resource_path)
		_update_status())
	line.add_child(edit)

func _range_field(parent: Control, owner: Resource, stats: Resource) -> void:
	var key := owner.resource_path + "::range_cells"
	var parts := PackedStringArray()
	for cell in stats.range_cells:
		parts.append("%d,%d" % [cell.x, cell.y])
	_text_field(parent, "range_cells", ";".join(parts), func(value):
		var points: Array[Vector2i] = []
		var valid := true
		for part in value.split(";", false):
			var coordinates: PackedStringArray = str(part).strip_edges().split(",")
			if coordinates.size() != 2 or not coordinates[0].strip_edges().is_valid_int() or not coordinates[1].strip_edges().is_valid_int():
				valid = false
				break
			points.append(Vector2i(int(coordinates[0]), int(coordinates[1])))
		if not valid or points.is_empty():
			invalid[key] = true
		else:
			invalid.erase(key)
			stats.range_cells = points
			model.mark_resource(owner.resource_path)
		_update_status())
func _references(id: String) -> String:
	var used := PackedStringArray()
	if category == 2:
		for actor_id in model.actors:
			var spec = model.actors[actor_id].stats.skill_spec
			if spec and spec.content_id == id: used.append(str(actor_id))
	else:
		for row in model.levels.rows:
			if row.values.type != "battle": continue
			if str(row.values.fixed_roster).split("|", false).has(id): used.append(str(row.values.name))
		for row in model.waves.rows:
			if row.values.enemy == id:
				var level := str(row.values.level)
				if not used.has(level): used.append(level)
	return "共用位置：" + ("、".join(used) if not used.is_empty() else "未发现引用")

func _update_status() -> void:
	if status == null: return
	if not invalid.is_empty(): status.text = "有无效数值，请修正后保存：" + "、".join(invalid.keys())
	elif model.has_changes(): status.text = "有未保存的修改；切换分类会保留草稿。"
	else: status.text = "已保存。"

func _save() -> bool:
	if not invalid.is_empty():
		status.text = "有无效数值，请修正后保存：" + "、".join(invalid.keys())
		return false
	var previous := selected
	var errors: PackedStringArray = model.save_all()
	if not errors.is_empty():
		status.text = "保存失败：\n" + "\n".join(errors)
		return false
	_populate_items(previous)
	status.text = "已保存。"

	return true

func _play() -> void:
	if selected_level.is_empty():
		status.text = "请先选择一个关卡。"
		return
	if _save(): play_requested.emit(selected_level)
