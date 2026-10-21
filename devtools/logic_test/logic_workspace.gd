extends Control
const UI = preload("res://devtools/ui/workspace_style.gd")
const ACCENT = Color("90b5e4")
const TestConfig = preload("res://devtools/logic_test/test_config.gd")
const Session = preload("res://devtools/logic_test/test_session.gd")
const Canvas = preload("res://devtools/logic_test/battle_canvas.gd")
var groups = TestConfig.catalog()
var session: RefCounted
var battle: RefCounted
var canvas: Control
var group_select: OptionButton
var case_select: OptionButton
var roster_select: OptionButton
var facing_select: OptionButton
var start_button: Button
var pause_button: Button
var demo_button: Button
var step_button: Button
var status: Label
var hint: Label
var rules: Label
var checks: Label
var log_label: Label
var inspector: Label
var selected = -1
var speed = 1.0
var event_lines: Array = []

func _ready() -> void:
	var layout = UI.shell(self, "Logic Test", ACCENT)
	var column = UI.scroll_body(layout)
	UI.heading(column, "核心战斗规则", "6个专项关 + 综合防守 · 场景可切换 · 预设演示与手动部署共用战斗规则", ACCENT)
	var selectors = HFlowContainer.new()
	column.add_child(selectors)
	group_select = OptionButton.new()
	for group in groups: group_select.add_item(group.name)
	selectors.add_child(group_select)
	case_select = OptionButton.new()
	selectors.add_child(case_select)
	group_select.item_selected.connect(func(_i): _fill_cases(); _load_case())
	case_select.item_selected.connect(func(_i): _load_case())
	var actions = HFlowContainer.new()
	column.add_child(actions)
	demo_button = _button(actions, "预设演示", _demo)
	start_button = _button(actions, "开始", func(): battle.start(); _refresh())
	pause_button = _button(actions, "暂停", _toggle_pause)
	step_button = _button(actions, "单步 1/60秒", _single_step)
	_button(actions, "重置", _reset)
	var speed_select = OptionButton.new()
	for label in ["1×", "2×", "4×"]: speed_select.add_item(label)
	speed_select.item_selected.connect(func(i): speed = [1.0, 2.0, 4.0][i])
	actions.add_child(speed_select)
	status = UI.text(column, "", 16, ACCENT)
	rules = UI.text(column, "", 15)
	var deployment = HFlowContainer.new()
	column.add_child(deployment)
	roster_select = OptionButton.new()
	deployment.add_child(roster_select)
	facing_select = OptionButton.new()
	for label in ["朝右 →", "朝下 ↓", "朝左 ←", "朝上 ↑"]: facing_select.add_item(label)
	facing_select.select(2)
	deployment.add_child(facing_select)
	_button(deployment, "撤退选中干员", _retreat)
	_button(deployment, "释放选中技能", _skill)
	hint = UI.text(column, "", 14)
	canvas = Canvas.new()
	canvas.cell_clicked.connect(_cell_clicked)
	column.add_child(canvas)
	UI.text(column, "青方块：干员 / 绿方块：医疗 / 红圆：地面敌人 / 紫三角：飞行 / 橙线：阻挡 / 细线：攻击目标 / 黄圈：出手动作。点击干员显示方向范围。", 13)
	inspector = UI.text(column, "", 14)
	checks = UI.text(column, "", 14)
	log_label = UI.text(column, "", 13)
	_fill_cases()
	_load_case()

func _button(parent: Node, label: String, callback: Callable) -> Button:
	var button = Button.new()
	button.text = label
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.pressed.connect(callback)
	parent.add_child(button)
	return button

func _fill_cases() -> void:
	case_select.clear()
	for item in groups[group_select.selected].cases: case_select.add_item(item.name)
	case_select.select(0)

func _load_case() -> void:
	session = Session.new(groups[group_select.selected].cases[case_select.selected])
	battle = session.battle
	canvas.config = battle.configuration()
	canvas.flashes.clear()
	canvas.set_meta("history_cursor", 0)
	selected = -1
	event_lines.clear()
	roster_select.clear()
	for key in canvas.config.roster:
		var unit: Dictionary = canvas.config.roster[key]
		roster_select.add_item("%s · 费用%.0f · %s" % [unit.name, unit.cost, "地面" if unit.terrain == "ground" else "高台"])
		roster_select.set_item_metadata(roster_select.item_count - 1, key)
	rules.text = session.spec.rules
	hint.text = "预设演示会重置并自动操作；手动：选编队单位及朝向，点击空格部署。每项规则独立验收。"
	_refresh()

func _demo() -> void:
	_load_case()
	session.start_demo()
	if not battle.snapshot().units.is_empty(): selected = battle.snapshot().units[0].id
	_refresh()

func _reset() -> void:
	_load_case()

func _toggle_pause() -> void:
	battle.set_paused(not battle.snapshot().paused)
	_refresh()

func _single_step() -> void:
	session.single_step()
	_refresh()

func _process(delta: float) -> void:
	if session == null: return
	session.advance(delta * speed)
	for flash in canvas.flashes: flash.ttl -= delta
	canvas.flashes = canvas.flashes.filter(func(f): return f.ttl > 0)
	_refresh()

func _cell_clicked(cell: Vector2i) -> void:
	for unit in battle.snapshot().units:
		if unit.cell == cell:
			selected = unit.id
			_refresh()
			return
	var key: String = roster_select.get_item_metadata(roster_select.selected)
	var result = battle.deploy(key, cell, facing_select.selected)
	if result.ok: selected = result.id
	_command_hint(result, "部署")

func _retreat() -> void:
	_command_hint(battle.retreat(selected), "撤退")
	if battle.find_unit(selected).is_empty(): selected = -1

func _skill() -> void:
	_command_hint(battle.activate_skill(selected), "技能")

func _command_hint(result: Dictionary, action: String) -> void:
	var reasons = {"finished": "战斗已结束", "wrong_terrain": "地形不符或不可部署", "occupied": "格子已占用", "already_deployed": "该编队干员已在场", "deploy_limit": "部署数量已达上限", "insufficient_cost": "费用不足", "redeploy_cooldown": "再部署冷却中", "unknown_unit": "请先选中在场干员", "not_running": "请先开始战斗", "skill_active": "技能已经生效", "no_skill": "该干员没有主动技能", "insufficient_sp": "技力不足"}
	hint.text = action + ("成功" if result.ok else "失败：" + reasons.get(result.reason, result.reason))
	_refresh()

func _refresh() -> void:
	session.collect()
	var state = battle.snapshot()
	# Session may already have consumed events while advancing; consume history by index.
	var shown: int = canvas.get_meta("history_cursor", 0)
	if shown > session.history.size(): shown = 0
	for i in range(shown, session.history.size()):
		var event: Dictionary = session.history[i]
		if event.type in ["damage", "heal"] and state.time - event.time < 0.25:
			var flash = event.duplicate(true)
			flash.ttl = 0.25 - (state.time - event.time)
			canvas.flashes.append(flash)
		if event.type != "attack_start":
			event_lines.append(_event_line(event))
			if event_lines.size() > 8: event_lines.pop_front()
	canvas.set_meta("history_cursor", session.history.size())
	canvas.state = state
	canvas.selected = selected
	canvas.queue_redraw()
	var phases = {"ready": "准备", "running": "战斗", "victory": "胜利", "defeat": "失败"}
	status.text = "%s%s · %.2fs · 费用 %.1f/%.0f · 部署 %d/%d · 基地 %d · 波次 %d · 剩余 %d / 击败 %d / 漏怪 %d" % [phases[state.phase], "（暂停）" if state.paused else "", state.time, state.cost, canvas.config.cost_cap, state.units.size(), canvas.config.deploy_limit, state.life, state.wave, state.remaining, state.killed, state.escaped]
	start_button.disabled = state.phase != "ready"
	pause_button.disabled = state.phase != "running" or session.complete
	pause_button.text = "继续" if state.paused else "暂停"
	step_button.disabled = state.phase != "running" or not state.paused or session.complete
	var lines: PackedStringArray = ["规则检查 · %s · 用例观察截止 %.0fs" % ["完成" if session.complete else "进行中", session.spec.duration]]
	for result in session.results: lines.append("[%s] %s；实际：%s" % [result.status, result.label, result.actual])
	checks.text = "\n".join(lines)
	log_label.text = "最近事件\n" + "\n".join(event_lines)
	var details: PackedStringArray = []
	for key in state.redeploy:
		if state.redeploy[key] > 0: details.append("%s 再部署 %.1fs" % [canvas.config.roster[key].name, state.redeploy[key]])
	var unit = battle.find_unit(selected)
	if not unit.is_empty():
		details.append("选中 #%d %s · HP %.1f/%.0f · 攻击 %.0f · %s · 阻挡 %s · 累计攻击 %d · SP %.1f/%.0f · 技能剩余 %.1fs" % [unit.id, unit.name, unit.hp, unit.max_hp, unit.attack, unit.damage_type, str(unit.blocked), unit.attack_count, unit.sp, unit.skill.required, unit.skill_left])
	inspector.text = "\n".join(details) if not details.is_empty() else "点击在场干员查看生命、阻挡、技能与范围。"

func _event_line(event: Dictionary) -> String:
	var label: String = {"deploy": "部署", "retreat": "撤退", "spawn": "出怪", "block": "阻挡", "unblock": "解除阻挡", "death": "死亡", "escape": "漏怪", "skill_start": "技能开启", "skill_end": "技能结束", "miss": "攻击落空", "finished": "战斗结束", "heal": "治疗", "damage": "伤害"}.get(event.type, event.type)
	return "%.2fs · %s #%s → #%s%s%s" % [event.time, label, str(event.get("source", "-")), str(event.get("target", "-")), " %.1f" % event.amount if event.has("amount") else "", " ★强化" if event.get("enhanced", false) else ""]
