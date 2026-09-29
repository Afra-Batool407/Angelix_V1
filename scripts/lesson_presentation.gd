extends Control
class_name LessonPresentation
## Shared 2D "presentation lesson" for the two verified Real Numbers cards:
##   math.u01.real-numbers ("1.1 Introduction to Real Numbers")
##   math.u01.real-numbers.rational-irrational-combination
##     ("Combination of Rational and Irrational Numbers")
##
## PowerPoint-style animated slides over a live Angel presenter. Runs as a
## CanvasLayer overlay from world_controller.gd (world state and player
## position preserved) or as a standalone scene from the menu (scene switch).
##
## Offline only: content comes from the topic JSON, replies from AngelBrain.
## Visual actions are the validated whitelist (show_number_line, mark_point,
## highlight_interval, show_caption, reveal_bullets) drawn with Control
## drawing + tweens. Voice (phase 2) keeps all narration visible as text.

signal presentation_finished
signal checkpoint_answered(was_correct: bool)
signal quiz_requested
signal score_requested(quiz_correct: int, practice_correct: int,
	practice_total: int)

const PRESENTER_FALLBACK_TEXT := "Angel is having trouble drawing right now — but the lesson text is all here."

## Number-line drawing metrics (fractions of the slide visual area).
const LINE_MARGIN := 0.09
const LINE_Y_FRACTION := 0.62
const LINE_THICKNESS := 3.0
const TICK_LEN := 8.0

var topic_id := ""
var topic_title := ""
var slides: Array = []
var slide_index := -1
var playing := false
var voice_enabled := false

var _brain: AngelBrain
var _rng := RandomNumberGenerator.new()
var _actions_done: Array = []
var _action_clock := 0.0
var _caption_labels: Array = []
var _bullet_labels: Array = []
var _checkpoint_done: Array = []
var _practice_correct := 0
var _practice_total := 0

@onready var _panel: PanelContainer = $Root/Panel
@onready var _title_label: Label = $Root/Panel/Layout/TopBar/TitleLabel
@onready var _close_button: Button = $Root/Panel/Layout/TopBar/CloseButton
@onready var _slide_area: Control = $Root/Panel/Layout/SlideArea
@onready var _visual: Control = $Root/Panel/Layout/SlideArea/Visual
@onready var _caption_box: VBoxContainer = $Root/Panel/Layout/SlideArea/Visual/CaptionBox
@onready var _bullets_box: VBoxContainer = $Root/Panel/Layout/SlideArea/Visual/BulletsBox
@onready var _angel_mood: Label = $Root/Panel/Layout/SlideArea/AngelHolder/AngelMood
@onready var _narration: Label = $Root/Panel/Layout/SlideArea/AngelHolder/Narration
@onready var _progress_label: Label = $Root/Panel/Layout/Controls/ProgressLabel
@onready var _back_button: Button = $Root/Panel/Layout/Controls/BackButton
@onready var _replay_button: Button = $Root/Panel/Layout/Controls/ReplayButton
@onready var _play_button: Button = $Root/Panel/Layout/Controls/PlayButton
@onready var _next_button: Button = $Root/Panel/Layout/Controls/NextButton


func _ready() -> void:
	_rng.randomize()
	_close_button.pressed.connect(_exit_pressed)
	_back_button.pressed.connect(_go_back)
	_next_button.pressed.connect(_go_next)
	_replay_button.pressed.connect(_replay_slide)
	_play_button.pressed.connect(_toggle_play)
	_visual.draw.connect(_draw_visual)
	set_process(false)


## Standalone entry (menu scene switch): load the topic and start.
func open_topic(new_topic_id: String) -> void:
	topic_id = new_topic_id
	_load_topic()
	visible = true
	_start()


## Overlay entry (world_controller instantiates inside its CanvasLayer).
func start_presentation(new_topic_id: String) -> void:
	open_topic(new_topic_id)


func _load_topic() -> void:
	var data := GameSession.load_topic_data(topic_id)
	if data.is_empty():
		_show_fallback("This lesson's content file is missing or invalid.")
		return
	topic_title = String(data.get("title", "Lesson"))
	slides = _validated_slides(data.get("slides", []))
	_brain = AngelBrain.new()
	_brain.setup(data)
	_title_label.text = topic_title
	if slides.is_empty():
		_show_fallback("No valid slides were found in this lesson's data.")
	else:
		_prepare_practice(data.get("practice", []))


## Validates the slide array against the schema; drops bad slides with a
## logged reason instead of crashing. Safe text-only fallback if all fail.
func _validated_slides(raw: Variant) -> Array:
	var ok: Array = []
	if not (raw is Array):
		push_error("LessonPresentation: slides is not an array")
		return ok
	for i: int in (raw as Array).size():
		var s: Variant = (raw as Array)[i]
		if not (s is Dictionary):
			push_error("LessonPresentation: slide %d is not a dict" % i)
			continue
		var slide: Dictionary = s
		var slide_id := String(slide.get("id", "?"))
		if String(slide.get("id", "")).is_empty():
			push_error("LessonPresentation: slide %d missing id" % i)
			continue
		if String(slide.get("narration", "")).is_empty() \
				or String(slide.get("caption", "")).is_empty():
			push_error("LessonPresentation: slide %s missing narration/caption" % slide_id)
			continue
		if _validate_actions(slide.get("animation_actions", []), slide_id) \
				and _validate_checkpoints(slide.get("checkpoints", []), slide_id):
			ok.append(slide)
	return ok


func _validate_actions(raw: Variant, slide_id: String) -> bool:
	if not (raw is Array):
		push_error("LessonPresentation: slide %s actions not an array" % slide_id)
		return false
	var at_seen := -1.0
	for a: Variant in (raw as Array):
		if not (a is Dictionary):
			push_error("LessonPresentation: %s action not a dict" % slide_id)
			return false
		var act: Dictionary = a
		var action := String(act.get("action", ""))
		var at := float(act.get("at", -1.0))
		if not is_finite(at) or at < 0.0:
			push_error("LessonPresentation: %s bad 'at'" % slide_id)
			return false
		if at < at_seen:
			push_error("LessonPresentation: %s actions out of order" % slide_id)
			return false
		at_seen = at
		match action:
			"show_number_line", "highlight_interval":
				var lo := float(act.get("from", NAN))
				var hi := float(act.get("to", NAN))
				if not (is_finite(lo) and is_finite(hi) and hi > lo):
					push_error("LessonPresentation: %s %s needs from<to" % [slide_id, action])
					return false
			"mark_point":
				if not is_finite(float(act.get("value", NAN))) \
						or String(act.get("label", "")).is_empty():
					push_error("LessonPresentation: %s mark_point bad" % slide_id)
					return false
			"show_caption":
				if String(act.get("text", "")).is_empty():
					push_error("LessonPresentation: %s show_caption empty" % slide_id)
					return false
			"reveal_bullets":
				var items: Variant = act.get("items", [])
				if not (items is Array) or (items as Array).is_empty():
					push_error("LessonPresentation: %s reveal_bullets empty" % slide_id)
					return false
			_:
				push_error("LessonPresentation: %s unknown action '%s'" % [slide_id, action])
				return false
	return true


func _validate_checkpoints(raw: Variant, slide_id: String) -> bool:
	if not (raw is Array):
		push_error("LessonPresentation: %s checkpoints not an array" % slide_id)
		return false
	for c: Variant in (raw as Array):
		if not (c is Dictionary):
			push_error("LessonPresentation: %s checkpoint not a dict" % slide_id)
			return false
		var cp: Dictionary = c
		for field: String in ["question", "hint", "correct_feedback", "retry_feedback"]:
			if String(cp.get(field, "")).is_empty():
				push_error("LessonPresentation: %s checkpoint missing %s" % [slide_id, field])
				return false
		var answers: Variant = cp.get("accepted_answers", [])
		if not (answers is Array) or (answers as Array).is_empty():
			push_error("LessonPresentation: %s checkpoint no accepted_answers" % slide_id)
			return false
	return true


## Practice scoring: each validated practice item counts once (first answer).
func _prepare_practice(raw: Variant) -> void:
	_practice_total = 0
	_practice_correct = 0
	if raw is Array:
		for p: Variant in (raw as Array):
			if p is Dictionary and not String((p as Dictionary).get("id", "")).is_empty():
				_practice_total += 1


func _show_fallback(reason: String) -> void:
	push_error("LessonPresentation fallback: " + reason)
	slides = []
	slide_index = -1
	_title_label.text = topic_title if topic_title != "" else "Lesson"
	_narration.text = PRESENTER_FALLBACK_TEXT
	_angel_mood.text = "Angel (text mode)"
	_progress_label.text = "0 / 0"
	_visual.queue_redraw()


# ------------------------------------------------------------- slide flow

func _start() -> void:
	slide_index = -1
	_checkpoint_done.clear()
	_go_next()


func _go_next() -> void:
	if slide_index + 1 >= slides.size():
		_finish_slides()
		return
	slide_index += 1
	_show_slide(slide_index)


func _go_back() -> void:
	if slide_index <= 0:
		return
	slide_index -= 1
	if slide_index < _checkpoint_done.size():
		_checkpoint_done[slide_index] = false
	_show_slide(slide_index)


func _replay_slide() -> void:
	if slide_index >= 0 and slide_index < slides.size():
		_show_slide(slide_index)


func _toggle_play() -> void:
	playing = not playing
	_play_button.text = "Pause" if playing else "Play"
	set_process(playing)


func _show_slide(index: int) -> void:
	_clear_slide_visuals()
	var slide: Dictionary = slides[index]
	_progress_label.text = "%d / %d" % [index + 1, slides.size()]
	_narration.text = String(slide.get("narration", ""))
	_narration.visible = true
	_angel_mood.text = "Angel"
	_play_button.text = "Pause"
	playing = true
	set_process(true)
	_action_clock = 0.0
	_actions_done.clear()
	_visual.queue_redraw()
	_speak(String(slide.get("narration", "")))


func _process(delta: float) -> void:
	if not playing or slide_index < 0 or slide_index >= slides.size():
		return
	_action_clock += delta
	var slide: Dictionary = slides[slide_index]
	var actions: Array = slide.get("animation_actions", [])
	for i: int in actions.size():
		if _actions_done.has(i):
			continue
		var at := float((actions[i] as Dictionary).get("at", 0.0))
		if _action_clock >= at:
			_actions_done.append(i)
			_apply_action(actions[i] as Dictionary)


func _clear_slide_visuals() -> void:
	for child: Node in _bullets_box.get_children():
		child.queue_free()
	for child: Node in _caption_box.get_children():
		child.queue_free()
	_caption_labels.clear()
	_bullet_labels.clear()
	_actions_done.clear()
	_action_clock = 0.0
	_visual.queue_redraw()


func _apply_action(act: Dictionary) -> void:
	match String(act.get("action", "")):
		"show_caption":
			_spawn_caption(String(act.get("text", "")))
		"reveal_bullets":
			for item: Variant in (act.get("items", []) as Array):
				_spawn_bullet(String(item))
		"mark_point":
			_spawn_point_label(String(act.get("label", "")))
			_visual.queue_redraw()
		"show_number_line", "highlight_interval":
			_visual.queue_redraw()


func _spawn_caption(text: String) -> void:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", Color(0.98, 0.72, 0.25))
	_caption_box.add_child(label)
	_caption_labels.append(label)
	label.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(label, "modulate:a", 1.0, 0.35)


func _spawn_bullet(text: String) -> void:
	var label := Label.new()
	label.text = "\u2022 " + text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 15)
	label.add_theme_color_override("font_color", Color(0.9, 0.93, 1.0))
	_bullets_box.add_child(label)
	_bullet_labels.append(label)
	label.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(label, "modulate:a", 1.0, 0.3)


func _spawn_point_label(text: String) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", Color(0.95, 0.96, 1.0))
	_caption_box.add_child(label)


# ------------------------------------------------------------- drawing
## All draw_line calls use the exact signature
## draw_line(from: Vector2, to: Vector2, color: Color, width: float).

func _line_y() -> float:
	return _visual.size.y * LINE_Y_FRACTION


func _line_x0() -> float:
	return _visual.size.x * LINE_MARGIN


func _line_x1() -> float:
	return _visual.size.x * (1.0 - LINE_MARGIN)


func _value_to_x(value: float, v_from: float, v_to: float) -> float:
	var span := maxf(v_to - v_from, 0.001)
	var t: float = clampf((value - v_from) / span, 0.0, 1.0)
	return lerpf(_line_x0(), _line_x1(), t)


func _draw_visual() -> void:
	if slide_index < 0 or slide_index >= slides.size():
		return
	var slide: Dictionary = slides[slide_index]
	var actions: Array = slide.get("animation_actions", [])
	var v_from := -3.0
	var v_to := 3.0
	var has_line := false
	for a: Variant in actions:
		var act := a as Dictionary
		if String(act.get("action", "")) == "show_number_line":
			v_from = float(act.get("from", v_from))
			v_to = float(act.get("to", v_to))
			has_line = true
	if not has_line:
		return
	var y := _line_y()
	var x0 := _line_x0()
	var x1 := _line_x1()
	var axis_color := Color(0.85, 0.88, 1.0)
	_visual.draw_line(Vector2(x0, y), Vector2(x1, y), axis_color, LINE_THICKNESS)
	_visual.draw_line(Vector2(x0, y - TICK_LEN), Vector2(x0, y + TICK_LEN), axis_color, LINE_THICKNESS)
	_visual.draw_line(Vector2(x1, y - TICK_LEN), Vector2(x1, y + TICK_LEN), axis_color, LINE_THICKNESS)
	# Integer ticks across the visible range.
	var first := int(ceilf(v_from))
	var last := int(floorf(v_to))
	for v: int in range(first, last + 1):
		var tx := _value_to_x(float(v), v_from, v_to)
		_visual.draw_line(Vector2(tx, y - TICK_LEN * 0.6), Vector2(tx, y + TICK_LEN * 0.6),
			Color(0.6, 0.65, 0.8), LINE_THICKNESS * 0.6)
		_visual.draw_string(ThemeDB.fallback_font, Vector2(tx - 4.0, y + 22.0), str(v),
			HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.75, 0.78, 0.9))
	# Applied point marks and interval highlights (action order preserved).
	for idx: int in actions.size():
		if not _actions_done.has(idx):
			continue
		var act: Dictionary = actions[idx]
		match String(act.get("action", "")):
			"mark_point":
				var px := _value_to_x(float(act.get("value", 0.0)), v_from, v_to)
				_visual.draw_circle(Vector2(px, y), 6.0, Color(0.98, 0.72, 0.25))
			"highlight_interval":
				var hx0 := _value_to_x(float(act.get("from", 0.0)), v_from, v_to)
				var hx1 := _value_to_x(float(act.get("to", 0.0)), v_from, v_to)
				_visual.draw_rect(Rect2(hx0, y - 10.0, maxf(hx1 - hx0, 3.0), 20.0),
					Color(0.4, 0.9, 0.6, 0.35))
				_visual.draw_line(Vector2(hx0, y), Vector2(hx1, y),
					Color(0.4, 0.9, 0.6), LINE_THICKNESS * 1.5)


# ---------------------------------------------------------------- finish

func _finish_slides() -> void:
	playing = false
	set_process(false)
	quiz_requested.emit()


func _exit_pressed() -> void:
	presentation_finished.emit()


func _speak(text: String) -> void:
	if voice_enabled:
		speak_narration(text)


## Phase 2 replaces this no-op with the verified VoiceManager call.
func speak_narration(_text: String) -> void:
	pass
