extends RefCounted
## Shared look-and-feel helpers used by every screen.
## Use it with:  const UI = preload("res://scripts/ui.gd")

const COL_BG := Color("#0f172a")
const COL_PANEL := Color("#1e293b")
const COL_TEXT := Color("#f8fafc")
const COL_MUTED := Color("#94a3b8")
const COL_GOOD := Color("#4ade80")
const COL_BAD := Color("#f87171")
const COL_WARN := Color("#fbbf24")
const COL_BUTTON := Color("#334155")
const COL_PRIMARY := Color("#2563eb")


## Adds the dark background and a padded vertical layout to `parent`.
## With scrollable = true the layout scrolls on small screens.
static func page_root(parent: Control, scrollable := false) -> VBoxContainer:
	var bg := ColorRect.new()
	bg.color = COL_BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	parent.add_child(bg)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		margin.add_theme_constant_override(side, 20)
	parent.add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 12)
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if scrollable:
		var scroll := ScrollContainer.new()
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		margin.add_child(scroll)
		scroll.add_child(root)
	else:
		margin.add_child(root)
	return root


## Set wrap = false for short labels that sit side by side in a row,
## otherwise they get squeezed into one character per line.
static func make_label(text: String, size: int, color: Color, wrap := true) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART if wrap else TextServer.AUTOWRAP_OFF
	return label


static func make_panel(color: Color) -> PanelContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(16)
	style.set_content_margin_all(16)
	panel.add_theme_stylebox_override("panel", style)
	return panel


static func make_button(text: String, font_size := 20, height := 64, color := COL_BUTTON) -> Button:
	var button := Button.new()
	button.text = text
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.custom_minimum_size = Vector2(0, height)
	button.add_theme_font_size_override("font_size", font_size)
	button.add_theme_stylebox_override("normal", _button_style(color))
	button.add_theme_stylebox_override("hover", _button_style(color.lightened(0.15)))
	button.add_theme_stylebox_override("pressed", _button_style(color.darkened(0.2)))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		button.add_theme_color_override(state, COL_TEXT)
	return button


static func _button_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(14)
	style.set_content_margin_all(10)
	return style


## Gives a progress bar a visible track and a green fill.
static func style_progress_bar(bar: ProgressBar) -> void:
	var track := StyleBoxFlat.new()
	track.bg_color = COL_PANEL
	track.set_corner_radius_all(9)
	var fill := StyleBoxFlat.new()
	fill.bg_color = COL_GOOD
	fill.set_corner_radius_all(9)
	bar.add_theme_stylebox_override("background", track)
	bar.add_theme_stylebox_override("fill", fill)


## Formats a whole number in Indian digit grouping, e.g. 2500000 -> "Rs 25,00,000".
static func fmt(amount: int) -> String:
	var negative := amount < 0
	var digits := str(absi(amount))
	if digits.length() > 3:
		var head := digits.substr(0, digits.length() - 3)
		var tail := digits.substr(digits.length() - 3)
		var parts := PackedStringArray()
		while head.length() > 2:
			parts.insert(0, head.substr(head.length() - 2))
			head = head.substr(0, head.length() - 2)
		if head.length() > 0:
			parts.insert(0, head)
		digits = ",".join(parts) + "," + tail
	return ("-" if negative else "") + "Rs " + digits


static func fmt_delta(delta: int) -> String:
	if delta > 0:
		return "+" + fmt(delta)
	if delta < 0:
		return fmt(delta)
	return "No money lost or gained"


## Reads a JSON file that must contain a list. Returns [] on any problem.
static func load_json_list(path: String) -> Array:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Cannot open " + path)
		return []
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_ARRAY:
		push_error(path + " must contain a list")
		return []
	return parsed
