extends SceneTree
const Config = preload("res://devtools/logic_test/test_config.gd")
const Session = preload("res://devtools/logic_test/test_session.gd")
var failures = 0
var cases = 0
var checks = 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(label)

func run() -> void:
	for group in Config.catalog():
		for spec in group.cases:
			var session = Session.new(spec)
			session.start_demo()
			session.advance(spec.duration + 1.0)
			cases += 1
			check(session.complete, spec.name + " completes")
			for result in session.results:
				check(result.status == "通过", "%s / %s: %s" % [spec.name, result.label, result.actual])
			var repeat = Session.new(spec)
			repeat.start_demo()
			for i in range(ceili((spec.duration + 1.0) * 60)):
				repeat.advance(1.0 / 60.0)
			check(repeat.battle.snapshot() == session.battle.snapshot(), spec.name + " replay independent of frame sizes")
	var scene = load("res://devtools/logic_test/logic_workspace.tscn")
	for i in range(3):
		var workspace = scene.instantiate()
		root.add_child(workspace)
		workspace.set_process(false)
		workspace._demo()
		workspace.session.advance(0.5)
		workspace.battle.set_paused(true)
		var before = workspace.battle.snapshot()
		workspace._process(1.0)
		check(workspace.battle.snapshot() == before, "workspace pause freezes battle")
		workspace._single_step()
		check(workspace.battle.snapshot().time > before.time, "workspace single step advances")
		workspace._reset()
		check(workspace.battle.snapshot().phase == "ready" and workspace.canvas.flashes.is_empty(), "reset clears state and effects")
		workspace.group_select.select(6)
		workspace._fill_cases()
		workspace._load_case()
		workspace._demo()
		workspace.session.advance(35.0)
		workspace._refresh()
		check(workspace.battle.snapshot().phase == "victory", "workspace switches to combined preset")
		workspace.queue_free()
		await process_frame
	print("Logic workspace: %d cases, %d checks, %d failures" % [cases, checks, failures])
	quit(1 if failures else 0)
