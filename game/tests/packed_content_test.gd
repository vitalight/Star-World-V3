extends SceneTree
## Runs from a PCK in an empty directory; no source checkout or temporary writes.
const Catalog = preload("res://game/content/content_catalog.gd")
const BattleScene = preload("res://game/battle/battle_scene.tscn")
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var catalog = Catalog.new()
	catalog.reload()
	if not catalog.errors.is_empty():
		push_error("\n".join(catalog.errors)); quit(1); return
	for id in catalog.levels:
		var game = BattleScene.instantiate()
		game.campaign_level = id
		game.set_process(false)
		root.add_child(game)
		if game.battle == null or not game.validation_errors.is_empty():
			failures += 1; push_error(id + ": " + "\n".join(game.validation_errors))
		for kind in ["before", "after"]:
			if catalog.levels[id][kind].is_empty(): continue
			var story = catalog.story(catalog.levels[id][kind])
			if not story.errors().is_empty(): failures += 1
		game.queue_free()
		await process_frame
	print("PACKED CONTENT: three battles, three stories and chapter epilogue, %d failures" % failures)
	quit(1 if failures else 0)
