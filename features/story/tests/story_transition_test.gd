extends SceneTree
const View = preload("res://features/story/story_view.gd")
var checks := 0
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
 checks += 1
 if not ok:
  failures += 1
  push_error(message)
func center(actor: Control) -> Vector2:
 return actor.position + actor.size * 0.5
func run() -> void:
 root.size = Vector2i(1280, 720)
 var view := View.new()
 var texture := GradientTexture2D.new()
 view.configure({"room": texture}, {"one": texture, "two": texture})
 root.add_child(view)
 await process_frame
 var solo := {"type": "line", "text": "solo", "background": "room", "actors": ["one"]}
 var pair := {"type": "line", "text": "pair", "background": "room", "actors": ["one", "two"]}
 view.show_snapshot(solo)
 var initial := center(view.actor_views[0])
 view.show_snapshot(pair)
 view.set_process(false)
 check(center(view.actor_views[0]).is_equal_approx(initial), "Same actor starts at former position")
 check(is_equal_approx(center(view.actor_views[1]).x, view.size.x * 0.69), "New actor starts at its target")
 view._process(view.ACTOR_MOVE_DURATION * 0.5)
 var middle := center(view.actor_views[0])
 check(middle.x < initial.x and middle.x > view.size.x * 0.31, "Actor moves smoothly toward left position")
 var swapped := pair.duplicate(true)
 swapped.actors = ["two", "one"]
 view.show_snapshot(swapped)
 view.set_process(false)
 check(center(view.actor_views[1]).is_equal_approx(middle), "Rapid change retains same actor current position across slots")
 check(view.actor_views[1].flip_h and not view.actor_views[0].flip_h, "Swapping starts from each actor's previous facing")
 view._process(0.06)
 check(view.actor_views[1].scale.x < 1.0 and view.actor_views[0].scale.x < 1.0, "Both changing actors turn during movement")
 view._process(0.12)
 check(not view.actor_views[1].flip_h and view.actor_views[0].flip_h, "Actors turn toward their new facing")
 view._process(view.ACTOR_MOVE_DURATION)
 check(is_equal_approx(center(view.actor_views[1]).x, view.size.x * 0.69), "Swapped actor reaches right position")
 check(is_equal_approx(center(view.actor_views[0]).x, view.size.x * 0.31), "Other actor reaches left position")
 check(view.actor_views[0].scale == Vector2.ONE and view.actor_views[1].scale == Vector2.ONE, "Automatic turns settle at full width")
 var mirrored_pair := pair.duplicate(true)
 mirrored_pair.actor_mirror = ["two"]
 view.show_snapshot(mirrored_pair)
 view.set_process(false)
 check(not view._anim_actor_flip.has("two"), "Matching explicit facing does not add a turn")
 view._process(view.ACTOR_MOVE_DURATION)
 var explicit_turn := swapped.duplicate(true)
 explicit_turn.anim_actor_flip = ["one"]
 view.show_snapshot(explicit_turn)
 view.set_process(false)
 check(view._anim_actor_flip.count("one") == 1, "Explicit flip is not duplicated by automatic turning")
 view._process(view.ACTOR_MOVE_DURATION)
 view.show_snapshot(solo)
 view.set_process(false)
 check(is_equal_approx(center(view.actor_views[0]).x, view.size.x * 0.69), "Pair to solo retains right actor position")
 view._process(view.ACTOR_MOVE_DURATION / 2.0)
 var ratio := center(view.actor_views[0]).x / view.size.x
 root.size = Vector2i(1600, 900)
 await process_frame
 check(is_equal_approx(center(view.actor_views[0]).x / view.size.x, ratio), "Resize keeps movement progress")
 view._process(view.ACTOR_MOVE_DURATION)
 check(is_equal_approx(center(view.actor_views[0]).x, view.size.x * 0.5), "Resize settles at new center")
 var effects := pair.duplicate(true)
 effects.anim_screen_shake = true
 effects.anim_actor_shake = ["one"]
 view.show_snapshot(effects)
 view.set_process(false)
 view._process(0.15)
 check(view._stage.position.length() > 0.0 and center(view.actor_views[0]).x < view.size.x * 0.5, "Movement and shakes run together")
 view.show_snapshot({"type": "end", "text": "", "actors": []})
 check(not view.is_processing() and not view.actor_views[0].visible, "End clears transition")
 view.show_snapshot(solo)
 check(is_equal_approx(center(view.actor_views[0]).x, view.size.x * 0.5) and view._move_from.is_empty(), "No transition from absent actor")
 view.queue_free()
 await process_frame
 print("STORY TRANSITION: %d checks, %d failures" % [checks, failures])
 quit(1 if failures else 0)
