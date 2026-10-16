extends Control
## Hook or Crook - life mode.
##
## One message at a time lands on the player's fake phone. The player can
## trust it, ignore it or report it. Scenarios live in data/scenarios.json and
## goals in data/goals.json, so both can grow without touching this script.

const UI = preload("res://scripts/ui.gd")
const SaveStore = preload("res://scripts/save_store.gd")

const SCENARIO_FILE := "res://data/scenarios.json"
const GOAL_FILE := "res://data/goals.json"
const MENU_SCENE := "res://scenes/menu.tscn"

const START_MONEY := 50000
const DAILY_SALARY := 5000
const MESSAGES_PER_DAY := 5

## A rank is earned once this many scams have been spotted.
const RANKS := [
	{"min": 0, "name": "Easy Target"},
	{"min": 3, "name": "Alert"},
	{"min": 8, "name": "Sharp"},
	{"min": 15, "name": "Cyber Guardian"},
	{"min": 30, "name": "Scam Hunter"},
]

const CHANNEL_NAMES := {
	"sms": "SMS",
	"whatsapp": "WhatsApp",
	"call": "Phone call",
	"email": "Email",
	"qr": "QR code",
	"ad": "Advert",
}

var scenarios: Array = []
var goals: Array = []
var queue: Array = []
var current: Dictionary = {}
var owned: Array = []

var money := START_MONEY
var day := 1
var seen_today := 0
var scams_spotted := 0
var scams_fallen := 0
var streak := 0
var best_streak := 0
var game_over := false

var scroll: ScrollContainer
var day_label: Label
var money_label: Label
var stats_label: Label
var goal_label: Label
var goal_bar: ProgressBar
var owned_label: Label
var salary_label: Label
var channel_label: Label
var message_label: Label
var action_box: HBoxContainer
var result_panel: PanelContainer
var headline_label: Label
var delta_label: Label
var explanation_label: Label
var flags_label: Label
var fix_label: Label
var bonus_label: Label
var next_button: Button


func _ready() -> void:
	scenarios = UI.load_json_list(SCENARIO_FILE)
	goals = UI.load_json_list(GOAL_FILE)
	_load_progress()
	_build_ui()
	if scenarios.is_empty():
		message_label.text = "No scenarios found. Check data/scenarios.json."
		action_box.visible = false
		return
	_next_message()


# ---------------------------------------------------------------- saving

func _load_progress() -> void:
	var data := SaveStore.load_data()
	best_streak = int(data.get("best_streak", 0))
	if not data.has("money") or int(data.get("money", 0)) <= 0:
		return
	money = int(data.get("money", START_MONEY))
	day = int(data.get("day", 1))
	seen_today = int(data.get("seen_today", 0))
	scams_spotted = int(data.get("scams_spotted", 0))
	scams_fallen = int(data.get("scams_fallen", 0))
	streak = int(data.get("streak", 0))
	owned = data.get("owned", [])


func _save_progress() -> void:
	var data := SaveStore.load_data()
	data["money"] = money
	data["day"] = day
	data["seen_today"] = seen_today
	data["scams_spotted"] = scams_spotted
	data["scams_fallen"] = scams_fallen
	data["streak"] = streak
	data["best_streak"] = best_streak
	data["owned"] = owned
	SaveStore.save_data(data)


# ---------------------------------------------------------------- UI

func _build_ui() -> void:
	var root := UI.page_root(self, true)
	scroll = root.get_parent() as ScrollContainer

	# Top bar: menu button, day, money.
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 10)
	root.add_child(top)
	var menu_button := UI.make_button("Menu", 16, 44)
	menu_button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	menu_button.pressed.connect(_on_menu_pressed)
	top.add_child(menu_button)
	day_label = UI.make_label("", 18, UI.COL_MUTED, false)
	day_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	day_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	top.add_child(day_label)
	money_label = UI.make_label("", 26, UI.COL_TEXT, false)
	money_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	top.add_child(money_label)

	stats_label = UI.make_label("", 16, UI.COL_MUTED)
	root.add_child(stats_label)

	goal_label = UI.make_label("", 18, UI.COL_TEXT)
	root.add_child(goal_label)
	goal_bar = ProgressBar.new()
	goal_bar.show_percentage = false
	goal_bar.custom_minimum_size = Vector2(0, 18)
	UI.style_progress_bar(goal_bar)
	root.add_child(goal_bar)

	owned_label = UI.make_label("", 16, UI.COL_GOOD)
	root.add_child(owned_label)
	salary_label = UI.make_label("", 16, UI.COL_WARN)
	root.add_child(salary_label)

	# The fake phone with the incoming message.
	var phone := UI.make_panel(UI.COL_PANEL)
	phone.custom_minimum_size = Vector2(0, 190)
	root.add_child(phone)
	var phone_box := VBoxContainer.new()
	phone_box.add_theme_constant_override("separation", 10)
	phone.add_child(phone_box)
	channel_label = UI.make_label("", 17, UI.COL_MUTED)
	phone_box.add_child(channel_label)
	message_label = UI.make_label("", 22, UI.COL_TEXT)
	phone_box.add_child(message_label)

	# Action buttons.
	action_box = HBoxContainer.new()
	action_box.add_theme_constant_override("separation", 10)
	root.add_child(action_box)
	for item in [["Trust it", "accept"], ["Ignore it", "ignore"], ["Report it", "report"]]:
		var button := UI.make_button(item[0], 20, 64)
		button.pressed.connect(_on_action.bind(item[1]))
		action_box.add_child(button)

	# "What just happened?" card, shown after each decision.
	result_panel = UI.make_panel(UI.COL_PANEL)
	result_panel.visible = false
	root.add_child(result_panel)
	var result_box := VBoxContainer.new()
	result_box.add_theme_constant_override("separation", 8)
	result_panel.add_child(result_box)
	headline_label = UI.make_label("", 24, UI.COL_TEXT)
	result_box.add_child(headline_label)
	delta_label = UI.make_label("", 20, UI.COL_TEXT)
	result_box.add_child(delta_label)
	bonus_label = UI.make_label("", 18, UI.COL_GOOD)
	result_box.add_child(bonus_label)
	explanation_label = UI.make_label("", 18, UI.COL_TEXT)
	result_box.add_child(explanation_label)
	flags_label = UI.make_label("", 16, UI.COL_WARN)
	result_box.add_child(flags_label)
	fix_label = UI.make_label("", 16, UI.COL_MUTED)
	result_box.add_child(fix_label)
	next_button = UI.make_button("Next message", 22, 60, UI.COL_PRIMARY)
	next_button.pressed.connect(_on_next_pressed)
	result_box.add_child(next_button)

	# Breathing room at the bottom when the page scrolls.
	var bottom_space := Control.new()
	bottom_space.custom_minimum_size = Vector2(0, 12)
	root.add_child(bottom_space)


# ---------------------------------------------------------------- game flow

func _next_message() -> void:
	salary_label.text = ""
	if seen_today >= MESSAGES_PER_DAY:
		day += 1
		seen_today = 0
		money += DAILY_SALARY
		salary_label.text = "Day %d: your salary of %s was credited." % [day, UI.fmt(DAILY_SALARY)]
	salary_label.visible = salary_label.text != ""
	if queue.is_empty():
		queue = scenarios.duplicate()
		queue.shuffle()
	current = queue.pop_back()
	seen_today += 1

	var channel: String = CHANNEL_NAMES.get(str(current.get("channel", "")), "Message")
	channel_label.text = "%s  -  from: %s" % [channel, str(current.get("sender", "Unknown"))]
	message_label.text = str(current.get("text", ""))
	result_panel.visible = false
	action_box.visible = true
	scroll.scroll_vertical = 0
	_update_hud()


func _on_action(action: String) -> void:
	var is_scam: bool = current.get("is_scam", false)
	var right: String = str(current.get("right_action", "ignore"))
	var old_rank := _rank_title()
	var delta := 0
	var headline := ""
	var color := UI.COL_GOOD
	var good := false

	if is_scam:
		if action == "accept":
			delta = int(current.get("money_if_wrong", 0))
			headline = "You got scammed"
			color = UI.COL_BAD
			scams_fallen += 1
		else:
			good = true
			scams_spotted += 1
			if action == right:
				delta = int(current.get("money_if_right", 0))
				headline = "Smart move"
			elif right == "report":
				headline = "Safe - but reporting it would have earned a bounty"
				color = UI.COL_WARN
			else:
				headline = "Safe move"
	else:
		if action == "accept":
			delta = int(current.get("money_if_right", 0))
			good = true
			headline = "Good call - this one was genuine"
		else:
			headline = "That one was real - you missed an opportunity"
			color = UI.COL_WARN

	money += delta
	if good:
		streak += 1
		best_streak = maxi(best_streak, streak)
	else:
		streak = 0

	# Bonus lines: rank-ups and unlocked goals.
	var bonus := PackedStringArray()
	var new_rank := _rank_title()
	if new_rank != old_rank:
		bonus.append("Rank up: %s" % new_rank)
	for goal in goals:
		var goal_id := str(goal.get("id", ""))
		var cost := int(goal.get("cost", 0))
		if not owned.has(goal_id) and money >= cost:
			owned.append(goal_id)
			bonus.append("Goal unlocked: %s (%s)! %s" % [str(goal.get("name", goal_id)), UI.fmt(cost), str(goal.get("blurb", ""))])

	headline_label.text = headline
	headline_label.add_theme_color_override("font_color", color)
	delta_label.text = UI.fmt_delta(delta)
	delta_label.add_theme_color_override("font_color", color)
	bonus_label.text = "\n".join(bonus)
	bonus_label.visible = not bonus.is_empty()
	explanation_label.text = str(current.get("explanation", ""))

	var flags: Array = current.get("red_flags", [])
	var flags_title := "Red flags:" if is_scam else "Why it was genuine:"
	var flag_lines := PackedStringArray()
	for flag in flags:
		flag_lines.append("- " + str(flag))
	flags_label.text = flags_title + "\n" + "\n".join(flag_lines)

	var fix := str(current.get("real_fix", ""))
	fix_label.text = ("In real life: " + fix) if fix != "" else ""
	fix_label.visible = fix != ""

	next_button.text = "Next message"
	if money <= 0:
		game_over = true
		headline_label.text += "\nGame over: you are broke."
		next_button.text = "Play again"

	action_box.visible = false
	result_panel.visible = true
	_update_hud()
	_save_progress()
	_scroll_to_result.call_deferred()


func _scroll_to_result() -> void:
	await get_tree().process_frame
	if is_inside_tree() and result_panel.visible:
		scroll.ensure_control_visible(next_button)


func _on_next_pressed() -> void:
	if game_over:
		_reset()
	_next_message()


func _on_menu_pressed() -> void:
	_save_progress()
	get_tree().change_scene_to_file(MENU_SCENE)


func _reset() -> void:
	money = START_MONEY
	day = 1
	seen_today = 0
	scams_spotted = 0
	scams_fallen = 0
	streak = 0
	owned = []
	game_over = false
	queue.clear()
	_save_progress()


func _update_hud() -> void:
	day_label.text = "Day %d" % day
	money_label.text = UI.fmt(money)
	stats_label.text = "Rank: %s   |   Streak %d (best %d)   |   Spotted %d, scammed %d" % [_rank_title(), streak, best_streak, scams_spotted, scams_fallen]

	var next_goal := _next_goal()
	if next_goal.is_empty():
		goal_label.text = "All goals reached. Keep your streak going!"
		goal_bar.max_value = 1
		goal_bar.value = 1
	else:
		var cost := int(next_goal.get("cost", 1))
		goal_label.text = "Next goal: %s  (%s)" % [str(next_goal.get("name", "?")), UI.fmt(cost)]
		goal_bar.max_value = cost
		goal_bar.value = clampi(money, 0, cost)

	var names := PackedStringArray()
	for goal in goals:
		if owned.has(str(goal.get("id", ""))):
			names.append(str(goal.get("name", "")))
	owned_label.text = "Owned: " + ", ".join(names) if not names.is_empty() else ""
	owned_label.visible = not names.is_empty()


# ---------------------------------------------------------------- helpers

func _next_goal() -> Dictionary:
	for goal in goals:
		if not owned.has(str(goal.get("id", ""))):
			return goal
	return {}


func _rank_title() -> String:
	var title := ""
	for rank in RANKS:
		if scams_spotted >= int(rank["min"]):
			title = str(rank["name"])
	return title
