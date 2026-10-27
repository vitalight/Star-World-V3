extends SceneTree
const View = preload("res://features/story/story_view.gd")
var failures := 0
var checks := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
 checks += 1
 if not ok:
  failures += 1
  push_error(message)
func run() -> void:
 root.size = Vector2i(1280, 720)
 var first := GradientTexture2D.new()
 first.width = 1600; first.height = 900
 var second := GradientTexture2D.new()
 second.width = 1600; second.height = 900
 var view := View.new()
 view.configure({"first": first, "second": second}, {})
 root.add_child(view)
 await process_frame
 var close := {"type": "line", "background": "first", "framing": "left_close", "actors": [], "text": "a"}
 var wide := {"type": "line", "background": "first", "framing": "wide", "actors": [], "text": "b"}
 view.show_snapshot(close)
 check(view.background.texture is AtlasTexture and is_equal_approx(view.background.texture.region.size.x, 960), "First shot loads directly in close framing")
 view.show_snapshot(wide)
 view.set_process(false)
 check(view.background.texture is AtlasTexture and is_equal_approx(view.background.texture.region.size.x, 960), "Framing transition starts from prior crop")
 view._process(view.BACKGROUND_TRANSITION_DURATION / 2.0)
 var midpoint: float = view.background.texture.region.size.x
 check(midpoint > 960 and midpoint < 1600, "Crop interpolates during transition")
 view.show_snapshot(close)
 view.set_process(false)
 check(is_equal_approx(view.background.texture.region.size.x, midpoint), "Reversing framing continues from current crop")
 view._process(view.BACKGROUND_TRANSITION_DURATION)
 check(is_equal_approx(view.background.texture.region.size.x, 960), "Reversed framing reaches close target")
 view.show_snapshot(wide)
 view.set_process(false)
 view._process(view.BACKGROUND_TRANSITION_DURATION)
 check(view.background.texture == first, "Wide framing reaches original full texture")
 var next := {"type": "line", "background": "second", "actors": [], "text": "c", "anim_screen_shake": true}
 view.show_snapshot(next)
 view.set_process(false)
 check(view.background.texture == second and view.background.modulate.a == 0.0 and view._previous_background.visible, "New image fades over old image")
 view._process(view.BACKGROUND_TRANSITION_DURATION / 2.0)
 check(view.background.modulate.a > 0.0 and view.background.modulate.a < 1.0, "Crossfade has intermediate alpha")
 check(view._previous_background.get_global_rect().encloses(view.get_global_rect()) and view.background.get_global_rect().encloses(view.get_global_rect()), "Both images cover screen during shake")
 var opacity := view.background.modulate.a
 view.show_snapshot(next)
 view.set_process(false)
 check(is_equal_approx(view.background.modulate.a, opacity) and view._previous_background.visible, "Advancing within the new image retains fade progress")
 root.size = Vector2i(1600, 900)
 await process_frame
 view._process(view.BACKGROUND_TRANSITION_DURATION)
 check(is_equal_approx(view.background.modulate.a, 1.0) and not view._previous_background.visible, "Crossfade settles after resize")
 view.show_snapshot({"type":"end", "actors":[], "text":""})
 check(view.background.texture == null and not view._previous_background.visible and not view.is_processing(), "Ending clears both backgrounds and transition")
 view.queue_free()
 await process_frame
 print("STORY BACKGROUND: %d checks, %d failures" % [checks, failures])
 quit(1 if failures else 0)
