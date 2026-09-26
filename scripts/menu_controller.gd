extends CanvasLayer
## Linear menu flow: subjects -> math chapters -> chapter 2 topics -> 3D terrain.
## State 0 = subjects, State 1 = chapters, State 2 = topics.

enum MenuState { SUBJECTS = 0, CHAPTERS = 1, TOPICS = 2 }

# ---------------------------------------------------------------
# Global configuration matrix (standard 9th grade PCTB classes)
# ---------------------------------------------------------------
const SUBJECTS := [
	{"title": "Math", "subtitle": "3 chapters", "enabled": true},
	{"title": "Physics", "subtitle": "Coming soon", "enabled": false},
	{"title": "Chemistry", "subtitle": "Coming soon", "enabled": false},
	{"title": "Biology", "subtitle": "Coming soon", "enabled": false},
	{"title": "English", "subtitle": "Coming soon", "enabled": false},
	{"title": "Urdu", "subtitle": "Coming soon", "enabled": false},
	{"title": "Islamiat", "subtitle": "Coming soon", "enabled": false},
	{"title": "Pak Studies", "subtitle": "Coming soon", "enabled": false},
]

const MATH_CHAPTERS := [
	{"title": "Chapter 1", "subtitle": "Matrices", "enabled": false},
	{"title": "Chapter 2", "subtitle": "Real & Rational Numbers", "enabled": true},
	{"title": "Chapter 3", "subtitle": "Logarithms", "enabled": false},
]

const CHAPTER2_TOPICS := [
	{"title": "Real Numbers", "subtitle": "Locked", "enabled": false},
	{"title": "Rational Numbers", "subtitle": "Open 3D World", "enabled": true},
	{"title": "Irrational Numbers", "subtitle": "Locked", "enabled": false},
	{"title": "Complex Numbers", "subtitle": "Locked", "enabled": false},
]

const TARGET_TOPIC := "Rational Numbers"
const TARGET_SCENE := "res://main.tscn"

const SLIDE_TIME := 0.22

const CARD_BG := Color(0.106, 0.129, 0.22)
const CARD_HOVER := Color(0.145, 0.176, 0.3)
const CARD_PRESSED := Color(0.086, 0.11, 0.19)
const CARD_DISABLED := Color(0.082, 0.098, 0.16)
const ACCENT := Color(0.42, 0.55, 1)
const PILL_MUTED := Color(0.3, 0.33, 0.45)
const TEXT_PRIMARY := Color(0.95, 0.96, 1)
const TEXT_MUTED := Color(0.6, 0.64, 0.78)
const TEXT_DISABLED := Color(0.5, 0.53, 0.65)

@onready var _content: Control = %Content
@onready var _grid: GridContainer = %Grid
@onready var _title_label: Label = %TitleLabel
@onready var _subtitle_label: Label = %SubtitleLabel
@onready var _back_button: Button = %BackButton

var _state: int = MenuState.SUBJECTS
var _busy := false
var _content_home := Vector2.ZERO


func _ready() -> void:
	_content_home = _content.position
	_back_button.pressed.connect(_go_back)
	_apply_state(MenuState.SUBJECTS)


func _on_card_pressed(item_title: String) -> void:
	if _busy:
		return
	match _state:
		MenuState.SUBJECTS:
			if item_title == "Math":
				_slide_to_state(MenuState.CHAPTERS)
		MenuState.CHAPTERS:
			if item_title == "Chapter 2":
				_slide_to_state(MenuState.TOPICS)
		MenuState.TOPICS:
			if item_title == TARGET_TOPIC:
				get_tree().change_scene_to_file(TARGET_SCENE)


func _go_back() -> void:
	if _busy:
		return
	if _state == MenuState.TOPICS:
		_slide_to_state(MenuState.CHAPTERS, false)
	elif _state == MenuState.CHAPTERS:
		_slide_to_state(MenuState.SUBJECTS, false)


func _apply_state(new_state: int) -> void:
	_state = new_state
	_refresh_header()
	_repopulate()


## Slides the whole content out, repopulates the grid, slides it back in.
## Forward = content exits left / enters from right; back = the reverse.
func _slide_to_state(new_state: int, forward: bool = true) -> void:
	if _busy or new_state == _state:
		return
	_busy = true

	var width := _content.size.x
	var out_x := _content_home.x - width if forward else _content_home.x + width
	var in_x := _content_home.x + width if forward else _content_home.x - width

	var out_tween := create_tween()
	out_tween.tween_property(_content, "position:x", out_x, SLIDE_TIME) \
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	await out_tween.finished

	_apply_state(new_state)
	_content.position = Vector2(in_x, _content_home.y)

	var in_tween := create_tween()
	in_tween.tween_property(_content, "position:x", _content_home.x, SLIDE_TIME) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	await in_tween.finished

	_busy = false


func _refresh_header() -> void:
	match _state:
		MenuState.SUBJECTS:
			_title_label.text = "Angelix"
			_subtitle_label.text = "9th Grade (PCTB) - Select a subject"
			_back_button.visible = false
		MenuState.CHAPTERS:
			_title_label.text = "Mathematics"
			_subtitle_label.text = "Select a chapter"
			_back_button.visible = true
		MenuState.TOPICS:
			_title_label.text = "Chapter 2"
			_subtitle_label.text = "Real & Rational Numbers"
			_back_button.visible = true


func _repopulate() -> void:
	for child in _grid.get_children():
		child.queue_free()

	var entries: Array = []
	match _state:
		MenuState.SUBJECTS:
			entries = SUBJECTS
		MenuState.CHAPTERS:
			entries = MATH_CHAPTERS
		MenuState.TOPICS:
			entries = CHAPTER2_TOPICS

	for entry in entries:
		_grid.add_child(_make_card(entry))


func _make_card(entry: Dictionary) -> Button:
	var enabled: bool = entry.get("enabled", true)

	var card := Button.new()
	card.custom_minimum_size = Vector2(0, 96)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.focus_mode = Control.FOCUS_NONE
	card.disabled = not enabled

	var radius := 18
	card.add_theme_stylebox_override("normal", _card_style(CARD_BG, radius))
	card.add_theme_stylebox_override("hover", _card_style(CARD_HOVER, radius))
	card.add_theme_stylebox_override("pressed", _card_style(CARD_PRESSED, radius))
	card.add_theme_stylebox_override("disabled", _card_style(CARD_DISABLED, radius))
	card.add_theme_stylebox_override("focus", StyleBoxEmpty.new())

	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.offset_left = 18.0
	box.offset_top = 12.0
	box.offset_right = -14.0
	box.offset_bottom = -12.0
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 6)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(box)

	var pill := Panel.new()
	var pill_style := StyleBoxFlat.new()
	pill_style.bg_color = ACCENT if enabled else PILL_MUTED
	pill_style.set_corner_radius_all(2)
	pill.add_theme_stylebox_override("panel", pill_style)
	pill.custom_minimum_size = Vector2(30, 4)
	pill.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(pill)

	var title := Label.new()
	title.text = String(entry["title"])
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.add_theme_font_size_override("font_size", 19)
	title.add_theme_color_override("font_color", TEXT_PRIMARY if enabled else TEXT_DISABLED)
	box.add_child(title)

	var subtitle_text := String(entry.get("subtitle", ""))
	if subtitle_text != "":
		var subtitle := Label.new()
		subtitle.text = subtitle_text
		subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		subtitle.add_theme_font_size_override("font_size", 13)
		subtitle.add_theme_color_override(
			"font_color", TEXT_MUTED if enabled else TEXT_DISABLED)
		box.add_child(subtitle)

	card.pressed.connect(_on_card_pressed.bind(String(entry["title"])))
	return card


func _card_style(bg: Color, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.set_corner_radius_all(radius)
	return style
