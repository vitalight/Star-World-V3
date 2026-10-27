extends SceneTree
const ScriptData = preload("res://features/story/story_script.gd")
const Session = preload("res://features/story/story_session.gd")
var checks := 0
var failures := 0

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)

func _initialize() -> void:
	var story = ScriptData.new()
	story.start = "intro"
	story.nodes = {
		"intro": {"type": "line", "text": "Hello", "next": "choice"},
		"choice": {"type": "choice", "text": "Route?", "choices": [
			{"text": "Left", "next": "left"}, {"text": "Right", "next": "right"}]},
		"left": {"type": "end", "text": "Left ending"},
		"right": {"type": "end", "text": "Right ending"}}
	var session = Session.new()
	check(session.snapshot().is_empty(), "Empty session is observable")
	check(not session.advance() and not session.choose(0) and not session.back(), "Empty session rejects input")
	check(session.load_story(story).is_empty(), "Valid graph loads")
	check(session.snapshot().id == "intro", "Starts on first dialogue")
	check(not session.back(), "First dialogue cannot go back")
	check(not session.choose(0), "Dialogue rejects choice input")
	check(session.advance(), "Advance reaches choice")
	check(not session.advance(), "Choice requires explicit input")
	check(not session.choose(-1) and not session.choose(2), "Invalid choices rejected")
	check(session.snapshot().history.size() == 2, "Invalid inputs do not change history")
	check(session.choose(0) and session.snapshot().id == "left", "Left branch ends correctly")
	check(session.snapshot().finished and not session.advance(), "Ending blocks advancement")
	check(session.snapshot().history[1].selected == "Left", "History records selected choice")
	check(session.back() and session.snapshot().id == "choice", "Back from ending returns to previous choice")
	check(session.snapshot().history.size() == 2 and not session.snapshot().history[1].has("selected"), "Back removes ending and old selection")
	check(session.choose(1) and session.snapshot().id == "right", "Choice can be changed after returning")
	session.restart()
	check(session.snapshot().id == "intro" and session.snapshot().history.size() == 1, "Replay resets cursor and history")
	session.advance()
	session.choose(1)
	check(session.snapshot().id == "right", "Replay can select other ending")
	var snapshot: Dictionary = session.snapshot()
	snapshot.history.clear()
	snapshot.text = "Changed"
	check(session.snapshot().history.size() == 3 and session.snapshot().text == "Right ending", "Snapshot is isolated")
	story.nodes.intro.text = "Mutated source"
	session.restart()
	check(session.snapshot().text == "Hello", "Loaded graph is isolated from source edits")
	var before: Dictionary = session.snapshot()
	story.nodes.intro.next = "missing"
	check(not session.load_story(story).is_empty(), "Missing target rejected")
	check(session.snapshot() == before, "Invalid reload preserves existing session")
	story.nodes.intro.next = "choice"
	story.nodes.choice.choices = []
	check(not story.errors().is_empty(), "Empty choice rejected")
	story.nodes.choice = {"type": "unknown", "text": "x"}
	check(not story.errors().is_empty(), "Unsupported node type rejected")
	story.start = "missing"
	check(not story.errors().is_empty(), "Missing start rejected")
	check(not session.load_story(null).is_empty(), "Null resource rejected")
	story.start = "intro"
	story.nodes.choice = {"type": "end", "text": "Done"}
	story.nodes.intro.actors = ["one", "two", "three"]
	check(not story.errors().is_empty(), "More than two actors rejected")
	story.nodes.intro.actors = ["one", "one"]
	check(not story.errors().is_empty(), "Duplicate actors rejected")
	story.nodes.intro.actors = ["one"]
	story.nodes.intro.speaker_actor = "missing"
	check(not story.errors().is_empty(), "Speaker must be present")
	story.nodes.intro.speaker_actor = "one"
	story.nodes.intro.background = 5
	check(not story.errors().is_empty(), "Non-string background rejected")
	story.nodes.intro.background = "winter"
	check(story.errors().is_empty(), "Optional presentation fields validate")
	story.nodes.intro.framing = "left_close"
	check(story.errors().is_empty(), "Close framing validates")
	story.nodes.intro.framing = "invalid"
	check(not story.errors().is_empty(), "Unknown framing rejected")
	print("Story rules: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
