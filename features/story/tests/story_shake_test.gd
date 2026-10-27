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
	var story = ScriptData.new()
	story.start = "line"
	story.nodes = {"line": {"type": "line", "text": "!", "next": "end", "actors": ["one", "two"], "screen_shake": true, "actor_shake": ["one"]}, "end": {"type": "end", "text": ""}}
	check(story.errors().is_empty(), "Screen and actor shakes can coexist")
	for bad in ["missing", ""]:
		story.nodes.line.actor_shake = [bad]
		check(not story.errors().is_empty(), "Absent shake target rejected")
	story.nodes.line.actor_shake = ["one", "one"]
	check(not story.errors().is_empty(), "Duplicate shake target rejected")
	story.nodes.line.actor_shake = "one"
	check(not story.errors().is_empty(), "Non-array shake rejected")
	story.nodes.line.actor_shake = []
	story.nodes.line.screen_shake = "true"
	check(not story.errors().is_empty(), "Non-boolean screen shake rejected")
	var texture := GradientTexture2D.new()
	var view := View.new()
	view.configure({"room": texture}, {"one": texture, "two": texture})
	root.add_child(view)
	var quiet := {"type": "line", "text": "Quiet", "background": "room", "actors": ["one", "two"], "speaker_actor": "one"}
	for dimensions in [Vector2i(960, 600), Vector2i(1600, 900)]:
		root.size = dimensions
		await process_frame
		view.show_snapshot(quiet)
		var rest := view.actor_views[0].position
		var other_rest := view.actor_views[1].position
		var background_rest := view.background.global_position
		var dialogue_rest := view.dialogue.global_position
		var button_rest := view.continue_button.global_position
		var screen := quiet.duplicate(true)
		screen.screen_shake = true
		view.show_snapshot(screen)
		view.set_process(false)
		view._process(0.07)
		var movement := view.actor_views[0].global_position - rest
		check(movement.length() > 0.1, "Screen shake moves scene")
		check((view.actor_views[1].global_position - other_rest).distance_to(movement) < 0.001, "Screen shake moves both actors together within subpixel precision")
		check(view.background.get_global_rect().encloses(view.get_global_rect()), "Overscan covers viewport during shake")
		check(view.dialogue.global_position == dialogue_rest and view.continue_button.global_position == button_rest, "Dialogue and input stay still")
		view._process(1.0)
		check(view.background.global_position.is_equal_approx(background_rest) and view.actor_views[0].position == rest, "Screen shake settles exactly")
		var actor := quiet.duplicate(true)
		actor.actor_shake = ["one"]
		view.show_snapshot(actor)
		view.set_process(false)
		view._process(0.07)
		check(view.actor_views[0].position.distance_to(rest) > 0.1, "Excited actor shakes")
		check(view.actor_views[1].position == other_rest and view.background.global_position == background_rest, "Actor shake isolates its target")
		view.show_snapshot(quiet)
		check(view.actor_views[0].position == rest and not view.is_processing(), "New line cancels old shake")
		view.show_snapshot(actor)
		view.set_process(false)
		view._process(0.07)
		check(view.actor_views[0].position.distance_to(rest) > 0.1, "Replaying a line restarts its shake")
		view.show_snapshot({"type": "end", "text": "", "actors": []})
		check(not view.is_processing() and view.background.global_position == background_rest, "Skip to ending cancels motion")
	# Resize during motion must not accumulate the old layout offset.
	var resizing := quiet.duplicate(true)
	resizing.screen_shake = true
	resizing.actor_shake = ["one"]
	view.show_snapshot(resizing)
	view.set_process(false)
	view._process(0.08)
	root.size = Vector2i(1280, 720)
	await process_frame
	view._process(1.0)
	var settled := view.actor_views[0].position
	view.show_snapshot(quiet)
	check(view.actor_views[0].position == settled and view.background.global_position == Vector2.ZERO, "Resize settles to new layout without drift")
	view.queue_free()
	await process_frame
	print("STORY SHAKE: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
