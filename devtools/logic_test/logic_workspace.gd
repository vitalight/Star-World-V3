extends Control
const UI = preload("res://devtools/ui/workspace_style.gd")
const ACCENT = Color("90b5e4")
const Battle = preload("res://features/battle/battle.gd")
const TestConfig = preload("res://devtools/logic_test/test_config.gd")
const Canvas = preload("res://devtools/logic_test/battle_canvas.gd")
var battle: RefCounted
var canvas: Control
var status: Label
var start_button: Button
var hint: Label

func _ready() -> void:
	battle = Battle.new(TestConfig.create())
	var layout := UI.shell(self, "Logic Test", ACCENT)
	var column := UI.scroll_body(layout)
	UI.heading(column, "规则验证", "在几何沙盒中检查部署、自动攻击与战斗胜负。", ACCENT)
	var toolbar := PanelContainer.new()
	column.add_child(toolbar)
	var toolbar_column := VBoxContainer.new()
	toolbar.add_child(toolbar_column)
	var actions := HFlowContainer.new()
	toolbar_column.add_child(actions)
	start_button = Button.new()
	start_button.text = "开始波次"
	start_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	start_button.pressed.connect(func(): battle.start(); _refresh())
	actions.add_child(start_button)
	var reset_button := Button.new()
	reset_button.text = "重置战场"
	reset_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	reset_button.pressed.connect(_reset)
	actions.add_child(reset_button)
	status = UI.text(toolbar_column, "", 16, ACCENT)
	hint = UI.text(column, "点击编号方格部署；四个位置全部部署可获胜，空场可检查失败流程。", 16)
	var field := PanelContainer.new()
	field.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(field)
	canvas = Canvas.new()
	canvas.config = TestConfig.create()
	canvas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	canvas.slot_clicked.connect(_deploy)
	field.add_child(canvas)
	canvas.custom_minimum_size.y = 350
	UI.text(column, "青色方块 · 我方    /    珊瑚色圆点 · 敌方    /    圆环 · 攻击范围    /    绿条 · 生命\n固定单波：8 名敌人，基地生命 3；波次开始前与进行中均可部署。", 14)
	_refresh()

func _process(delta: float) -> void:
	if battle == null:
		return
	battle.advance(delta)
	for flash in canvas.flashes:
		flash.ttl -= delta
	canvas.flashes = canvas.flashes.filter(func(flash): return flash.ttl > 0.0)
	for event in battle.take_events():
		if event.type == "attack":
			event.ttl = 0.14
			canvas.flashes.append(event)
	_refresh()

func _deploy(index: int) -> void:
	if battle.deploy(index):
		hint.text = "已部署位置 %d；自动攻击优先锁定最接近基地的敌人。" % (index + 1)
	else:
		hint.text = "无法部署：位置已占用或战斗已结束。可重置战场后重试。"
	_refresh()

func _reset() -> void:
	battle.reset()
	canvas.flashes.clear()
	hint.text = "已重置战场。点击编号方格部署，再开始波次。"
	_refresh()

func _refresh() -> void:
	var state = battle.snapshot()
	canvas.state = state
	start_button.disabled = state.phase != "ready"
	var phases := {"ready": "准备中", "running": "战斗中", "victory": "胜利", "defeat": "失败"}
	status.text = "%s   ·   基地生命 %d   /   剩余 %d   /   击败 %d   /   漏怪 %d" % [phases.get(state.phase, state.phase), state.life, state.remaining, state.killed, state.escaped]
	canvas.queue_redraw()
