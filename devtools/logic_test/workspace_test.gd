extends SceneTree
## Integration smoke checks for the sandbox configuration and lifecycle.
const Battle = preload("res://features/battle/battle.gd")
const Config = preload("res://devtools/logic_test/test_config.gd")
var failures = 0

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var battle = Battle.new(Config.create())
	for i in range(4):
		battle.deploy(i)
	battle.start()
	battle.advance(60.0)
	check(battle.snapshot().phase == "victory" and battle.snapshot().killed == 8, "all four slots win with all enemies killed")
	battle.reset()
	battle.start()
	battle.advance(60.0)
	check(battle.snapshot().phase == "defeat", "empty layout loses")
	var scene = load("res://devtools/logic_test/logic_workspace.tscn")
	for i in range(3):
		var workspace = scene.instantiate()
		root.add_child(workspace)
		workspace._deploy(0)
		workspace.battle.start()
		workspace._process(1.0)
		check(workspace.battle.snapshot().spawned == 1, "workspace starts isolated battle")
		workspace._reset()
		check(workspace.battle.snapshot().phase == "ready" and workspace.canvas.flashes.is_empty(), "workspace reset clears simulation and effects")
		workspace.queue_free()
		await process_frame
	print("Logic workspace: %d failures" % failures)
	quit(1 if failures else 0)

func check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		push_error(label)
