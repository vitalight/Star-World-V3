extends SceneTree

const Player = preload("res://game/player/player_mode.tscn")
const SAVE := "res://temp/chapter_one/selection_progress.cfg"
var failures := 0
var checks := 0
var player: Control

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)

func settle() -> void:
	for i in 8: await process_frame

func click_card(card: Button) -> void:
	var point := card.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new()
	motion.position = point; motion.global_position = point
	root.push_input(motion, true)
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = point; event.global_position = point
		event.button_index = MOUSE_BUTTON_LEFT; event.pressed = pressed
		root.push_input(event, true)
	await settle()

func verify_list(unlocked_count: int, locked: bool) -> void:
	var list: VBoxContainer = player.find_child("LevelList", true, false)
	check(list.get_child_count() == unlocked_count + int(locked), "Only unlocked levels and one next placeholder are visible")
	var placeholder := list.find_child("LockedLevel", false, false)
	check((placeholder != null) == locked, "Locked level placeholder matches progress")
	if placeholder:
		check(placeholder is not BaseButton and placeholder.focus_mode == Control.FOCUS_NONE and placeholder.tooltip_text.is_empty(), "Locked level cannot be selected and has no tooltip")
	var chapter := player.find_child("LockedChapter", true, false)
	check(chapter != null and chapter is not BaseButton and chapter.focus_mode == Control.FOCUS_NONE and chapter.tooltip_text.is_empty(), "Locked chapter is anonymous and cannot be selected")

func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://temp/chapter_one")
	if FileAccess.file_exists(SAVE): DirAccess.remove_absolute(SAVE)
	player = Player.instantiate()
	player.save_path = SAVE
	root.add_child(player)
	await settle()
	player.show_levels()
	await settle()
	verify_list(1, true)
	check(player.find_child("LevelType", true, false).text == "剧情", "Story detail shows story badge")
	var first_card: Control = player.find_child("Level_scene_0101A", true, false)
	check(first_card.find_child("RouteType", true, false).text == "剧情" and first_card.find_child("RouteTypeBadge", true, false).mouse_filter == Control.MOUSE_FILTER_IGNORE, "Story row shows a non-interactive story badge")
	var ids: Array = player.catalog.levels.keys()
	var previous: String = player.progress.selected
	player._select_level(ids[1])
	check(player.progress.selected == previous, "Locked level cannot be selected through the action")
	for i in 5: player.progress.completed.append(ids[i])
	player.progress.selected = ids[5]
	player.show_levels()
	await settle()
	verify_list(6, true)
	check(player.find_child("LevelType", true, false).text == "战斗", "Battle detail shows battle badge")
	var battle_card: Control = player.find_child("Level_scene_0101B", true, false)
	check(battle_card.find_child("RouteType", true, false).text == "战斗", "Battle row shows battle badge")
	var scroll: ScrollContainer = player.find_child("LevelScroll", true, false)
	var selected: Control = player.find_child("Level_" + ids[5], true, false)
	check(selected.get_global_rect().intersection(scroll.get_global_rect()).size.y >= selected.get_global_rect().size.y - 1, "Selected level is scrolled into view")
	player.progress.completed.assign(ids)
	player.progress.selected = ids.back()
	player.show_levels()
	await settle()
	verify_list(ids.size(), false)
	var panel: Control = player.find_child("LevelDetail", true, false)
	var detail_scroll: ScrollContainer = player.find_child("DetailScroll", true, false)
	check(absf(panel.get_global_rect().get_center().y - detail_scroll.get_global_rect().get_center().y) < 2, "Short detail panel is vertically centered")
	var short_height := panel.size.y
	var entry: Dictionary = player.catalog.levels[ids.back()]
	var old_name: String = entry.name
	entry.name = "很长的关卡标题需要在标签左侧换行".repeat(5)
	player.show_levels()
	await settle()
	var title: Control = player.find_child("DetailTitle", true, false)
	var badge: Control = player.find_child("LevelTypeBadge", true, false)
	check(title.get_global_rect().end.x <= badge.get_global_rect().position.x, "Long title does not overlap type badge")
	entry.name = old_name
	var old_description: String = entry.description
	entry.description = "很长的关卡说明用于验证自动换行和面板高度。".repeat(100)
	player.show_levels()
	await settle()
	panel = player.find_child("LevelDetail", true, false)
	detail_scroll = player.find_child("DetailScroll", true, false)
	check(panel.size.y > short_height and detail_scroll.get_v_scroll_bar().max_value > detail_scroll.get_v_scroll_bar().page, "Long detail expands and can scroll")
	entry.description = old_description
	player.developer_mode = true
	player.show_levels()
	await settle()
	scroll = player.find_child("LevelScroll", true, false)
	scroll.scroll_vertical = 220
	await settle()
	var original_scroll := scroll.scroll_vertical
	check(original_scroll > 0, "Developer level list is scrolled")
	var upper_card: Button = player.find_child("Level_" + ids[3], true, false)
	await click_card(upper_card)
	scroll = player.find_child("LevelScroll", true, false)
	check(player.progress.selected == ids[3] and scroll.scroll_vertical == original_scroll, "Selecting an earlier level preserves list scroll position")
	var lower_card: Button = player.find_child("Level_" + ids[6], true, false)
	await click_card(lower_card)
	scroll = player.find_child("LevelScroll", true, false)
	check(player.progress.selected == ids[6] and scroll.scroll_vertical == original_scroll, "Selecting a later level preserves list scroll position")
	player.queue_free()
	await settle()
	print("LEVEL SELECTION: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
