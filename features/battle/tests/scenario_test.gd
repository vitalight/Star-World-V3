extends SceneTree
const Config = preload("res://features/battle/tests/scenario_fixtures.gd")
const Session = preload("res://features/battle/tests/scenario_replay.gd")
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
			session.start_replay()
			session.advance(spec.duration + 1.0)
			cases += 1
			check(session.complete, spec.name + " completes")
			for result in session.results:
				check(result.status == "通过", "%s / %s: %s" % [spec.name, result.label, result.actual])
			var repeat = Session.new(spec)
			repeat.start_replay()
			for i in range(ceili((spec.duration + 1.0) * 60)):
				repeat.advance(1.0 / 60.0)
			check(repeat.battle.snapshot() == session.battle.snapshot(), spec.name + " replay independent of frame sizes")
	print("Battle scenarios: %d cases, %d checks, %d failures" % [cases, checks, failures])
	quit(1 if failures else 0)
