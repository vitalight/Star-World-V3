extends SceneTree
const View = preload("res://features/story/story_view.gd")
const ScriptData = preload("res://features/story/story_script.gd")
var checks := 0
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(label)
func run() -> void:
	var script := ScriptData.new()
	script.start = "line"
	script.nodes = {"line": {"type": "line", "text": "Turn", "actors": ["one", "two"], "next": "end"}, "end": {"type": "end", "text": ""}}
	for field in ["actor_flip", "actor_mirrored", "actor_exit_left", "actor_exit_right"]:
		script.nodes.line[field] = ["one", "two"]
		check(script.errors().is_empty(), field + " accepts visible targets")
		for invalid in [["missing"], ["one", "one"], "one"]:
			script.nodes.line[field] = invalid
			check(not script.errors().is_empty(), field + " rejects invalid targets")
		script.nodes.line.erase(field)
	script.nodes.line.actor_exit_left = ["one"]
	script.nodes.line.actor_exit_right = ["one"]
	check(not script.errors().is_empty(), "Same actor cannot exit both directions")
	script.nodes.line.erase("actor_exit_left")
	script.nodes.line.erase("actor_exit_right")
	script.nodes.line.actor_exit = ["one"]
	check(not script.errors().is_empty(), "Old undirected exit cue is rejected")
	script.nodes.line.erase("actor_exit")
	var view := View.new()
	var texture := GradientTexture2D.new()
	view.configure({"room": texture}, {"one": texture, "two": texture})
	root.add_child(view)
	var quiet := {"type": "line", "text": "Quiet", "background": "room", "actors": ["one", "two"]}
	for dimensions in [Vector2i(960, 600), Vector2i(1600, 900)]:
		root.size = dimensions
		await process_frame
		view.show_snapshot(quiet)
		check(view.actor_views[0].flip_h and not view.actor_views[1].flip_h, "Dialogue defaults to mirrored left and original right")
		var solo := quiet.duplicate(true)
		solo.actors = ["one"]
		view.show_snapshot(solo)
		check(view.actor_views[0].flip_h, "Centered solo actor defaults to mirrored right-facing pose")
		var override_facing := quiet.duplicate(true)
		override_facing.actor_mirrored = ["two"]
		view.show_snapshot(override_facing)
		check(not view.actor_views[0].flip_h and view.actor_views[1].flip_h, "Authored facing can override layout defaults")
		view.show_snapshot(quiet)
		var rest := view.actor_views[0].position
		var other_rest := view.actor_views[1].position
		var ui_rest := view.dialogue.global_position
		var turn := quiet.duplicate(true)
		turn.actor_flip = ["one"]
		turn.actor_mirrored = ["one"]
		view.show_snapshot(turn)
		view.set_process(false)
		check(not view.actor_views[0].flip_h, "Turn starts from opposite of authored facing")
		view._process(0.06)
		check(view.actor_views[0].scale.x < 1.0 and view.actor_views[0].scale.x > 0.0, "Turn passes through a narrow profile")
		check(view.actor_views[1].scale == Vector2.ONE and not view.actor_views[1].flip_h, "Turn only affects target")
		view._process(0.12)
		check(view.actor_views[0].flip_h, "Second half faces authored direction")
		view._process(0.5)
		check(view.actor_views[0].scale.is_equal_approx(Vector2.ONE) and view.actor_views[0].flip_h, "Turn settles at full width and final facing")
		var facing := quiet.duplicate(true)
		facing.actor_mirrored = ["one"]
		view.show_snapshot(facing)
		check(view.actor_views[0].flip_h and not view.is_processing(), "Next beat preserves explicit facing without another turn")
		var leave := quiet.duplicate(true)
		leave.actor_exit_left = ["one", "two"]
		view.show_snapshot(leave)
		view.set_process(false)
		view._process(0.15)
		check(view.actor_views[0].position.x < rest.x and view.actor_views[0].modulate.a < 1.0, "Left exit moves left and fades actors")
		check(view.actor_views[0].visible and view.actor_views[1].visible and view.actor_views[0].modulate.a == view.actor_views[1].modulate.a, "Both actors exit together")
		check(view.dialogue.global_position == ui_rest, "Actor motion keeps dialogue fixed")
		var right := quiet.duplicate(true)
		right.actor_exit_right = ["one", "two"]
		view.show_snapshot(right)
		view.set_process(false)
		view._process(0.15)
		check(view.actor_views[0].position.x > rest.x and view.actor_views[1].position.x > other_rest.x, "Right exit moves both actors right")
		var split := quiet.duplicate(true)
		split.actor_exit_left = ["one"]
		split.actor_exit_right = ["two"]
		view.show_snapshot(split)
		view.set_process(false)
		view._process(0.15)
		check(view.actor_views[0].position.x < rest.x and view.actor_views[1].position.x > other_rest.x, "Different actors may leave in opposite directions")
		view.show_snapshot(leave)
		view.set_process(false)
		view._process(0.15)
		root.size += Vector2i(32, 18)
		await process_frame
		view._process(0.5)
		check(not view.actor_views[0].visible and not view.actor_views[1].visible, "Both stay offstage after exit and resize")
		view.show_snapshot(quiet)
		check(view.actor_views[0].visible and view.actor_views[1].visible and view.actor_views[0].modulate.a == 1.0 and view.actor_views[0].flip_h, "New beat resets visibility, opacity and default facing")
		view.show_snapshot(turn)
		view.set_process(false)
		view._process(0.06)
		view.show_snapshot(quiet)
		check(view.actor_views[0].scale == Vector2.ONE and not view.is_processing(), "Fast advance cancels partial turn")
		view.show_snapshot(leave)
		view.set_process(false)
		view._process(0.2)
		view.show_snapshot(leave)
		check(view.actor_views[0].visible and view.actor_views[0].modulate.a == 1.0, "Replay starts departure from the beginning")
		view.show_snapshot({"type": "end", "text": "", "actors": []})
		check(not view.is_processing() and not view.actor_views[0].visible and view.actor_views[0].scale == Vector2.ONE, "Skip cancels departure without stale transform")
	view.queue_free()
	await process_frame
	print("STORY ACTOR MOTION: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
