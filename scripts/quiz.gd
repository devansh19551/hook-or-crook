extends Control
## Quick Quiz: ten short statements, the player decides "Scam" or "Legit".
## Questions live in data/quiz.json. The best score is saved.

const UI = preload("res://scripts/ui.gd")
const SaveStore = preload("res://scripts/save_store.gd")

const QUIZ_FILE := "res://data/quiz.json"
const MENU_SCENE := "res://scenes/menu.tscn"
const QUESTIONS_PER_ROUND := 10

var bank: Array = []
var round_questions: Array = []
var current: Dictionary = {}
var index := 0
var score := 0
var new_best := false

var progress_label: Label
var score_label: Label
var question_panel: PanelContainer
var question_label: Label
var answer_box: HBoxContainer
var result_panel: PanelContainer
var verdict_label: Label
var explanation_label: Label
var next_button: Button
var end_panel: PanelContainer
var end_title: Label
var end_message: Label
var end_best: Label


func _ready() -> void:
	bank = UI.load_json_list(QUIZ_FILE)
	_build_ui()
	if bank.is_empty():
		question_label.text = "No questions found. Check data/quiz.json."
		answer_box.visible = false
		return
	_start_round()


# ---------------------------------------------------------------- UI

func _build_ui() -> void:
	var root := UI.page_root(self, true)

	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 10)
	root.add_child(top)
	var menu_button := UI.make_button("Menu", 16, 44)
	menu_button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	menu_button.pressed.connect(_on_menu_pressed)
	top.add_child(menu_button)
	progress_label = UI.make_label("", 18, UI.COL_MUTED, false)
	progress_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	progress_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	top.add_child(progress_label)
	score_label = UI.make_label("", 22, UI.COL_TEXT, false)
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	top.add_child(score_label)

	var heading := UI.make_label("Scam or Legit?", 30, UI.COL_TEXT)
	root.add_child(heading)

	question_panel = UI.make_panel(UI.COL_PANEL)
	question_panel.custom_minimum_size = Vector2(0, 220)
	root.add_child(question_panel)
	question_label = UI.make_label("", 24, UI.COL_TEXT)
	question_panel.add_child(question_label)

	answer_box = HBoxContainer.new()
	answer_box.add_theme_constant_override("separation", 10)
	root.add_child(answer_box)
	var scam_button := UI.make_button("Scam", 24, 72)
	scam_button.pressed.connect(_on_answer.bind(true))
	answer_box.add_child(scam_button)
	var legit_button := UI.make_button("Legit", 24, 72)
	legit_button.pressed.connect(_on_answer.bind(false))
	answer_box.add_child(legit_button)

	result_panel = UI.make_panel(UI.COL_PANEL)
	result_panel.visible = false
	root.add_child(result_panel)
	var result_box := VBoxContainer.new()
	result_box.add_theme_constant_override("separation", 10)
	result_panel.add_child(result_box)
	verdict_label = UI.make_label("", 26, UI.COL_TEXT)
	result_box.add_child(verdict_label)
	explanation_label = UI.make_label("", 20, UI.COL_TEXT)
	result_box.add_child(explanation_label)
	next_button = UI.make_button("Next question", 22, 60, UI.COL_PRIMARY)
	next_button.pressed.connect(_on_next_pressed)
	result_box.add_child(next_button)

	end_panel = UI.make_panel(UI.COL_PANEL)
	end_panel.visible = false
	root.add_child(end_panel)
	var end_box := VBoxContainer.new()
	end_box.add_theme_constant_override("separation", 12)
	end_panel.add_child(end_box)
	end_title = UI.make_label("", 34, UI.COL_TEXT)
	end_box.add_child(end_title)
	end_message = UI.make_label("", 22, UI.COL_TEXT)
	end_box.add_child(end_message)
	end_best = UI.make_label("", 18, UI.COL_WARN)
	end_box.add_child(end_best)
	var again := UI.make_button("Play again", 22, 60, UI.COL_PRIMARY)
	again.pressed.connect(_start_round)
	end_box.add_child(again)
	var back := UI.make_button("Back to menu", 20, 56)
	back.pressed.connect(_on_menu_pressed)
	end_box.add_child(back)


# ---------------------------------------------------------------- flow

func _start_round() -> void:
	round_questions = bank.duplicate()
	round_questions.shuffle()
	round_questions = round_questions.slice(0, mini(QUESTIONS_PER_ROUND, round_questions.size()))
	index = 0
	score = 0
	new_best = false
	_show_question()


func _show_question() -> void:
	current = round_questions[index]
	question_label.text = str(current.get("text", ""))
	progress_label.text = "Question %d / %d" % [index + 1, round_questions.size()]
	score_label.text = "Score %d" % score
	question_panel.visible = true
	answer_box.visible = true
	result_panel.visible = false
	end_panel.visible = false


func _on_answer(says_scam: bool) -> void:
	var is_scam: bool = current.get("is_scam", false)
	var correct := says_scam == is_scam
	if correct:
		score += 1
		verdict_label.text = "Correct - it was a scam" if is_scam else "Correct - it was legit"
		verdict_label.add_theme_color_override("font_color", UI.COL_GOOD)
	else:
		verdict_label.text = "Not quite - it was a scam" if is_scam else "Not quite - it was legit"
		verdict_label.add_theme_color_override("font_color", UI.COL_BAD)
	explanation_label.text = str(current.get("explanation", ""))
	score_label.text = "Score %d" % score
	next_button.text = "See my score" if index >= round_questions.size() - 1 else "Next question"
	answer_box.visible = false
	result_panel.visible = true


func _on_next_pressed() -> void:
	index += 1
	if index >= round_questions.size():
		_show_end()
	else:
		_show_question()


func _show_end() -> void:
	var data := SaveStore.load_data()
	var best := int(data.get("quiz_best", 0))
	if score > best:
		new_best = true
		best = score
		data["quiz_best"] = best
		SaveStore.save_data(data)

	var total := round_questions.size()
	end_title.text = "%d / %d" % [score, total]
	end_message.text = _verdict_for(score, total)
	end_best.text = ("New best score!" if new_best else "Best score: %d / %d" % [best, QUESTIONS_PER_ROUND])
	question_panel.visible = false
	answer_box.visible = false
	result_panel.visible = false
	end_panel.visible = true


func _verdict_for(points: int, total: int) -> String:
	var ratio := float(points) / float(maxi(total, 1))
	if ratio >= 0.9:
		return "Scam Hunter level. Teach your family what you know."
	if ratio >= 0.7:
		return "Sharp. A few tricky ones slipped through, so play again."
	if ratio >= 0.5:
		return "Alert, but scammers could still catch you. Read the explanations and retry."
	return "Easy target for now. Play again and read each explanation carefully."


func _on_menu_pressed() -> void:
	get_tree().change_scene_to_file(MENU_SCENE)
