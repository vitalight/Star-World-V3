extends SceneTree
const Battle = preload("res://features/battle/battle.gd")
const Catalog = preload("res://devtools/art_test/asset_catalog.gd")
var checks := 0
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(message)
func settle() -> void:
	for frame in 6: await process_frame
func capture(name: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://temp/verification/" + name + ".png")
func run() -> void:
	root.size = Vector2i(1280,800)
	var icons := Catalog.skills()
	check(icons.size() == 16,"All sixteen atlas icons are catalogued")
	var areas := {}
	for entry in icons:
		check(entry.texture is AtlasTexture and entry.texture.get_image().get_size().x > 0,"Icon slice loads")
		areas[entry.texture.region] = true
	check(areas.size() == 16,"Icon slices are distinct")
	var game = load("res://game/battle/battle_scene.tscn").instantiate()
	root.add_child(game); game.set_process(false)
	await settle()
	var pure = Battle.new(game.configuration)
	var assigned := {}
	for key in game.configuration.roster:
		var skill: Dictionary = game.configuration.roster[key].skill
		check(skill.enabled and not skill.name.is_empty() and not skill.description.is_empty(),"Operator has named active skill: " + key)
		var icon: Texture2D = game.appearances[key].skill_icon
		check(icon is AtlasTexture and icon.atlas.resource_path == "res://content/ui/skill_icons/atlas.png","Operator uses formal atlas icon: " + key)
		assigned[icon.resource_path] = true
	check(assigned.size() == 5,"Every operator has its own icon")
	for args in preload("res://game/tests/defense_fixture.gd").deployments():
		pure.callv("deploy",args); game.command("deploy",args)
	pure.start(); game.start()
	var activated := {}
	for tick in 1600:
		for unit in pure.snapshot().units:
			if unit.skill_left <= 0 and unit.sp + 0.000001 >= unit.skill.required:
				if not activated.has(unit.roster_id):
					game.select_cell(unit.cell); await settle()
					check(game.hud.skill_button.icon == game.appearances[unit.roster_id].skill_icon and not game.hud.skill_button.disabled,"Ready skill uses matching clickable icon")
					check(game.hud.skill_description.text.contains(unit.skill.name),"Details display actual skill name")
					await capture("skill_game_" + unit.roster_id)
				activated[unit.roster_id] = true
				check(pure.activate_skill(unit.id).ok and game.command("activate_skill",[unit.id]).ok,"Real skill activation succeeds")
		pure.advance(0.05); game.battle.advance(0.05); game.refresh(0.05)
		if pure.snapshot().phase in ["victory","defeat"]: break
	check(activated.size() == 5,"All five skills charge and activate in a real battle")
	check(pure.snapshot() == game.last_state,"Pure and assembled battle results agree with all skills enabled")
	check(game.last_state.phase == "victory","Five-skill defense remains winnable")
	game.free(); await process_frame
	var art = load("res://devtools/art_test/art_workspace.tscn").instantiate()
	art.page = 4; root.add_child(art)
	await settle()
	check(art.tabs.get_tab_title(4) == "Skill" and art.tabs.current_tab == 4,"Art Test exposes Skill tab")
	check(art.skill_grid.get_child_count() == 16,"Skill page displays the full atlas")
	var labels: Array[Node] = art.tabs.get_child(4).find_children("*","Label",true,false)
	check(labels.all(func(label): return not ["技力","回复","释放","Game Test","攻击力","防御力","治疗量"].any(func(word): return label.text.contains(word))),"Art Skill page contains no gameplay descriptions")
	for dimensions in [Vector2i(1280,800),Vector2i(960,600),Vector2i(1600,900)]:
		root.size = dimensions; await settle()
		await capture("skill_art_%dx%d" % [dimensions.x,dimensions.y])
		var scroll: ScrollContainer = art.skill_grid.get_parent().get_parent()
		scroll.scroll_vertical = int(scroll.get_v_scroll_bar().max_value)
		await settle(); await capture("skill_atlas_%dx%d" % [dimensions.x,dimensions.y])
		scroll.scroll_vertical = 0
	art.free(); await process_frame
	print("SKILL INTEGRATION: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
