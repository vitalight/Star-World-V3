extends SceneTree

const View = preload("res://features/story/story_view.gd")
var failures := 0

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var view = View.new()
	root.add_child(view)
	await process_frame
	view.show_snapshot({"type": "line", "text": "甲\n乙"})
	view.set_process(false)
	check(view.is_typing() and view.dialogue.visible_characters == 0, "Dialogue begins hidden")
	view._process(0.04)
	check(view.dialogue.visible_characters == 1, "First character appears")
	view._process(0.04)
	check(view.dialogue.visible_characters == 2, "Newline is reached")
	view._process(0.59)
	check(view.dialogue.visible_characters == 2, "New line pauses for 0.6 seconds")
	view._process(0.011)
	check(not view.is_typing() and view.dialogue.visible_characters == 3, "Second line appears after pause")
	view.show_snapshot({"type": "line", "text": "新对白"})
	check(view.is_typing() and view.dialogue.visible_characters == 0, "Changing dialogue restarts animation")
	check(view.reveal_dialogue() and not view.is_typing() and view.dialogue.visible_characters == -1, "Reveal shows full dialogue")
	check(not view.reveal_dialogue(), "Completed dialogue can advance")
	view.show_snapshot({"type": "end", "text": ""})
	check(not view.is_typing(), "Ending stops animation")
	view.queue_free()
	print("Story typing: %d failures" % failures)
	quit(1 if failures else 0)
