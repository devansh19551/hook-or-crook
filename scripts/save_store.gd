extends RefCounted
## Saves progress to the phone (user://save.json) so players can continue later.
## Use it with:  const SaveStore = preload("res://scripts/save_store.gd")

const PATH := "user://save.json"
## Kept even when the player starts a new life.
const KEEP_KEYS := ["quiz_best", "best_streak"]


static func load_data() -> Dictionary:
	if not FileAccess.file_exists(PATH):
		return {}
	var file := FileAccess.open(PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) == TYPE_DICTIONARY:
		return parsed
	return {}


static func save_data(data: Dictionary) -> void:
	var file := FileAccess.open(PATH, FileAccess.WRITE)
	if file == null:
		push_error("Cannot write " + PATH)
		return
	file.store_string(JSON.stringify(data))


## Starts a fresh life but keeps high scores.
static func new_game() -> void:
	var old := load_data()
	var keep := {}
	for key in KEEP_KEYS:
		if old.has(key):
			keep[key] = old[key]
	save_data(keep)


## Deletes the save file (used by tests).
static func clear() -> void:
	if FileAccess.file_exists(PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
