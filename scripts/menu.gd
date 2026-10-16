extends Control
## Title screen: continue a saved life, start a new one, or play the quick quiz.

const UI = preload("res://scripts/ui.gd")
const SaveStore = preload("res://scripts/save_store.gd")

const LIFE_SCENE := "res://scenes/life.tscn"
const QUIZ_SCENE := "res://scenes/quiz.tscn"


func _ready() -> void:
	var root := UI.page_root(self)
	root.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_theme_constant_override("separation", 16)

	var title := UI.make_label("Hook or Crook", 52, UI.COL_TEXT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(title)

	var tagline := UI.make_label("Spot the scam. Keep your money. Build your life.", 20, UI.COL_MUTED)
	tagline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(tagline)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 30)
	root.add_child(spacer)

	var data := SaveStore.load_data()
	var has_save := data.has("money")

	if has_save:
		var cont := UI.make_button("Continue  (Day %d, %s)" % [int(data.get("day", 1)), UI.fmt(int(data.get("money", 0)))], 22, 72, UI.COL_PRIMARY)
		cont.pressed.connect(_on_continue)
		root.add_child(cont)
	var new_label := "New life (erases saved progress)" if has_save else "Start new life"
	var new_game := UI.make_button(new_label, 22, 72, UI.COL_BUTTON if has_save else UI.COL_PRIMARY)
	new_game.pressed.connect(_on_new_game)
	root.add_child(new_game)

	var quiz := UI.make_button("Quick Quiz: Scam or Legit?", 22, 72)
	quiz.pressed.connect(_on_quiz)
	root.add_child(quiz)

	if data.has("quiz_best"):
		var best := UI.make_label("Best quiz score: %d / 10" % int(data["quiz_best"]), 18, UI.COL_WARN)
		best.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		root.add_child(best)

	var footer := UI.make_label("Real help: call 1930 (cyber fraud helpline) or report at cybercrime.gov.in", 16, UI.COL_MUTED)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(footer)


func _on_continue() -> void:
	get_tree().change_scene_to_file(LIFE_SCENE)


func _on_new_game() -> void:
	SaveStore.new_game()
	get_tree().change_scene_to_file(LIFE_SCENE)


func _on_quiz() -> void:
	get_tree().change_scene_to_file(QUIZ_SCENE)
