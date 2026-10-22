extends RefCounted
## Test-only command replay and observations. It never edits battle state.
const Battle = preload("res://features/battle/battle.gd")
var battle: RefCounted
var spec: Dictionary
var history: Array = []
var results: Array = []
var command_results: Array = []
var replaying = false
var complete = false
var cursor = 0
var accumulator = 0.0
var observations = {"hp_cap": true, "block_max": 0, "block_overflow": false, "stopped": false, "walked": false, "latest": false, "latest_bad": false, "phase_at_gap": ""}
var previous: Dictionary = {}

func _init(case_spec: Dictionary) -> void:
	spec = case_spec.duplicate(true)
	battle = Battle.new(spec.config)
	results = spec.checks.map(func(check): return {"label": check.label, "status": "待验证", "actual": "尚无足够证据"})

func start_replay() -> void:
	replaying = true
	_execute_due()
	battle.start()
	collect()

func advance(delta: float) -> void:
	if complete or battle.snapshot().paused or battle.snapshot().phase != "running": return
	accumulator += delta
	while accumulator + 0.000001 >= Battle.STEP and not complete:
		accumulator -= Battle.STEP
		_tick(false)

func single_step() -> void:
	if not complete and battle.snapshot().paused and battle.snapshot().phase == "running": _tick(true)

func _tick(single: bool) -> void:
	if replaying: _execute_due()
	if single: battle.step()
	else: battle.advance(Battle.STEP)
	collect()
	var state = battle.snapshot()
	if state.phase in ["victory", "defeat"] or state.time + 0.000001 >= spec.duration:
		complete = true
		battle.set_paused(true)
		evaluate()

func _execute_due() -> void:
	while cursor < spec.commands.size() and spec.commands[cursor].at <= battle.snapshot().time + 0.000001:
		var command: Dictionary = spec.commands[cursor]
		var before: float = battle.snapshot().cost
		var result: Dictionary = {}
		if command.op == "deploy":
			result = battle.deploy(command.roster, command.cell, command.facing)
		else:
			var id = roster_unit(command.roster)
			if command.op == "retreat": result = battle.retreat(id)
			elif command.op == "skill": result = battle.activate_skill(id)
		var expected: String = command.get("reason", "")
		var valid: bool = result.ok == expected.is_empty() and result.reason == expected
		if not result.ok: valid = valid and is_equal_approx(before, battle.snapshot().cost)
		command_results.append({"ok": valid, "op": command.op, "expected": expected, "actual": result.reason})
		cursor += 1

func roster_unit(roster_id: String) -> int:
	for unit in battle.snapshot().units:
		if unit.roster_id == roster_id: return unit.id
	return -1

func collect() -> Array:
	var events = battle.take_events()
	history.append_array(events)
	var state = battle.snapshot()
	for unit in state.units:
		observations.hp_cap = observations.hp_cap and unit.hp <= unit.max_hp and unit.hp >= 0
		observations.block_max = maxi(observations.block_max, unit.blocked.size())
		observations.block_overflow = observations.block_overflow or unit.blocked.size() > unit.block
	for enemy in state.enemies:
		observations.hp_cap = observations.hp_cap and enemy.hp <= enemy.max_hp and enemy.hp >= 0
		if not previous.is_empty() and state.time > previous.time:
			for old in previous.enemies:
				if old.id != enemy.id: continue
				if not old.action.is_empty() and not enemy.action.is_empty() and is_equal_approx(old.distance, enemy.distance): observations.stopped = true
				if old.action.is_empty() and enemy.action.is_empty() and enemy.cooldown > 0 and enemy.distance > old.distance: observations.walked = true
	for event in events:
		if event.type != "attack_start" or event.friendly: continue
		for enemy in state.enemies:
			if enemy.id != event.source or not enemy.ranged or enemy.blocked_by != -1: continue
			var latest = -1
			for unit in state.units:
				if unit.hp > 0 and unit.position.distance_to(enemy.position) <= enemy.range + 0.000001: latest = maxi(latest, unit.id)
			if latest != -1:
				observations.latest = true
				observations.latest_bad = observations.latest_bad or latest != event.target
	if state.time >= 10.0 and state.time < 11.0: observations.phase_at_gap = state.phase
	previous = state
	evaluate()
	return events

func event_matches(event: Dictionary, check: Dictionary) -> bool:
	if event.type != check.type: return false
	for key in check.get("fields", {}):
		if not event.has(key): return false
		var value = check.fields[key]
		if value is float:
			if not is_equal_approx(float(event[key]), value): return false
		elif event[key] != value: return false
	return true

func evaluate() -> void:
	var state = battle.snapshot()
	for i in range(spec.checks.size()):
		var check: Dictionary = spec.checks[i]
		var passed = false
		var actual = ""
		var final_only = false
		match check.kind:
			"event", "no_event":
				var count = history.filter(func(event): return event_matches(event, check)).size()
				passed = count >= check.get("minimum", 1) if check.kind == "event" else count == 0
				actual = "%s：%d次" % [check.type, count]
				final_only = check.kind == "no_event"
			"state":
				var value = observations.phase_at_gap if check.field == "phase_at_gap" else state.get(check.field)
				passed = value == check.value
				actual = "%s = %s；预期 %s" % [check.field, str(value), str(check.value)]
				final_only = check.field != "phase_at_gap"
			"commands":
				passed = command_results.size() == spec.commands.size() and command_results.all(func(r): return r.ok)
				actual = "预设命令 %d/%d；匹配 %d" % [command_results.size(), spec.commands.size(), command_results.filter(func(r): return r.ok).size()]
			"enemy_motion":
				passed = observations.stopped and observations.walked
				actual = "动作停步 %s；冷却移动 %s" % [str(observations.stopped), str(observations.walked)]
			"latest_target":
				passed = observations.latest and not observations.latest_bad
				actual = "已观察 %s；违反优先级 %s" % [str(observations.latest), str(observations.latest_bad)]
				final_only = true
			"block_capacity":
				passed = observations.block_max == check.count and not observations.block_overflow
				actual = "最大阻挡 %d；超额 %s" % [observations.block_max, str(observations.block_overflow)]
				final_only = true
			"hp_cap":
				passed = observations.hp_cap
				actual = "生命范围合法：%s" % str(passed)
				final_only = true
		results[i].status = "通过" if passed and (complete or not final_only) else ("失败" if complete else "待验证")
		results[i].actual = actual
