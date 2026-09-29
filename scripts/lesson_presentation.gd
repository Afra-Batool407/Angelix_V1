extends Control
class_name LessonPresentation
## Shared 2D "presentation lesson" for the two verified Real Numbers cards:
##   math.u01.real-numbers ("1.1 Introduction to Real Numbers")
##   math.u01.real-numbers.rational-irrational-combination
##     ("Combination of Rational and Irrational Numbers")
##
## PowerPoint-style animated slides with an Angel presenter, offline voice
## output (verified DisplayServer TTS; text always visible), typed answers
## (no verified STT plugin exists, so listening is text-only), prepared
## checkpoints, scored practice + three-question quiz, and a transparent
## understanding score persisted via LearningProgress.
##
## Flow: slides -> scored practice -> quiz -> understanding score.
## Offline only: content from the topic JSON, replies from AngelBrain.

signal presentation_finished

const PRESENTER_FALLBACK_TEXT := "Angel is having trouble drawing right now — but the lesson text is all here."

## Number-line drawing metrics (fractions of the slide visual area).
const LINE_MARGIN := 0.09
const LINE_Y_FRACTION := 0.62
const LINE_THICKNESS := 3.0
const TICK_LEN := 8.0

enum Phase { SLIDES, PRACTICE, QUIZ, SCORE }

var topic_id := ""
var topic_title := ""
var slides: Array = []
var slide_index := -1
var playing := false
var voice_enabled := false

var _phase: int = Phase.SLIDES
var _voice := VoiceManager.new()
var _listen := ListenManager.new()
var _presenter := AngelPresenter.new()
var _brain: AngelBrain
var _actions_done: Array = []
var _action_clock := 0.0
var _checkpoint_done: Array = []
var _awaiting_checkpoint: Dictionary = {}
var _practice_items: Array = []
var _practice_index := 0
var _practice_correct := 0
var _practice_awaiting_selfcheck := false
var _quiz_data: Array = []
var _quiz_index := 0
var _quiz_correct := 0
var _quiz_answered_first: Array = []

@onready var _panel: PanelContainer = $Root/Panel
@onready var _title_label: Label = $Root/Panel/Layout/TopBar/TitleLabel
@onready var _close_button: Button = $Root/Panel/Layout/TopBar/CloseButton
@onready var _slide_area: Control = $Root/Panel/Layout/SlideArea
@onready var _visual: Control = $Root/Panel/Layout/SlideArea/Visual
@onready var _caption_box: VBoxContainer = $Root/Panel/Layout/SlideArea/Visual/CaptionBox
@onready var _bullets_box: VBoxContainer = $Root/Panel/Layout/SlideArea/Visual/BulletsBox
@onready var _angel_holder: VBoxContainer = $Root/Panel/Layout/SlideArea/AngelHolder
@onready var _pivot: Control = $Root/Panel/Layout/SlideArea/AngelHolder/PresenterPivot
@onready var _angel_mood: Label = $Root/Panel/Layout/SlideArea/AngelHolder/PresenterPivot/AngelBadge/AngelMood
@onready var _narration: Label = $Root/Panel/Layout/SlideArea/AngelHolder/Narration
@onready var _answer_edit: LineEdit = $Root/Panel/Layout/SlideArea/AngelHolder/ChatRow/AnswerEdit
@onready var _send_button: Button = $Root/Panel/Layout/SlideArea/AngelHolder/ChatRow/SendButton
@onready var _listen_button: Button = $Root/Panel/Layout/SlideArea/AngelHolder/ChatRow/ListenButton
@onready var _progress_label: Label = $Root/Panel/Layout/Controls/ProgressLabel
@onready var _back_button: Button = $Root/Panel/Layout/Controls/BackButton
@onready var _replay_button: Button = $Root/Panel/Layout/Controls/ReplayButton
@onready var _play_button: Button = $Root/Panel/Layout/Controls/PlayButton
@onready var _next_button: Button = $Root/Panel/Layout/Controls/NextButton
@onready var _quiz_panel: VBoxContainer = $Root/Panel/Layout/QuizPanel
@onready var _question_label: Label = $Root/Panel/Layout/QuizPanel/QuestionLabel
@onready var _choices_box: VBoxContainer = $Root/Panel/Layout/QuizPanel/ChoicesBox
@onready var _quiz_feedback: Label = $Root/Panel/Layout/QuizPanel/QuizFeedback
@onready var _score_panel: VBoxContainer = $Root/Panel/Layout/ScorePanel
@onready var _score_value: Label = $Root/Panel/Layout/ScorePanel/ScoreValue
@onready var _score_detail: Label = $Root/Panel/Layout/ScorePanel/ScoreDetail
@onready var _score_next: Label = $Root/Panel/Layout/ScorePanel/ScoreNext
@onready var _done_button: Button = $Root/Panel/Layout/ScorePanel/DoneButton


func _ready() -> void:
	_close_button.pressed.connect(_exit_pressed)
	_back_button.pressed.connect(_go_back)
	_next_button.pressed.connect(_go_next)
	_replay_button.pressed.connect(_replay_slide)
	_play_button.pressed.connect(_toggle_play)
	_send_button.pressed.connect(_on_send_pressed)
	_answer_edit.text_submitted.connect(func(_t: String) -> void: _on_send_pressed())
	_listen_button.pressed.connect(_on_listen_pressed)
	_done_button.pressed.connect(_exit_pressed)
	_visual.draw.connect(_draw_visual)
	voice_enabled = _voice.available
	if not _listen.available:
		_listen_button.tooltip_text = _listen.status_text()
	set_process(false)


## Standalone entry (menu scene switch): load the topic and start.
func open_topic(new_topic_id: String) -> void:
	topic_id = new_topic_id
	_load_topic()
	visible = true
	if not slides.is_empty():
		_presenter.attach(_pivot)
		_start()


## Overlay entry (world_controller instantiates inside its CanvasLayer).
func start_presentation(new_topic_id: String) -> void:
	open_topic(new_topic_id)


func _exit_pressed() -> void:
	_voice.stop()
	presentation_finished.emit()


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
		return
	_prepare_practice(data.get("practice", []))
	_prepare_quiz(data.get("quiz", []))


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


## Scored practice: reviewed prompt/solution pairs; the student's FIRST
## self-check response per item is the scored first answer.
func _prepare_practice(raw: Variant) -> void:
	_practice_items = []
	if raw is Array:
		for p: Variant in (raw as Array):
			if p is Dictionary and not String((p as Dictionary).get("id", "")).is_empty():
				_practice_items.append(p)
	_practice_index = 0
	_practice_correct = 0


func _prepare_quiz(raw: Variant) -> void:
	_quiz_data = []
	if raw is Array:
		for q: Variant in (raw as Array):
			if q is Dictionary:
				_quiz_data.append(q)
	_quiz_index = 0
	_quiz_correct = 0
	_quiz_answered_first.clear()


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
	_phase = Phase.SLIDES
	slide_index = -1
	_checkpoint_done.clear()
	_go_next()


func _go_next() -> void:
	if _phase != Phase.SLIDES:
		return
	if slide_index + 1 >= slides.size():
		_start_practice()
		return
	slide_index += 1
	_show_slide(slide_index)


func _go_back() -> void:
	if _phase != Phase.SLIDES or slide_index <= 0:
		return
	slide_index -= 1
	if slide_index < _checkpoint_done.size():
		_checkpoint_done[slide_index] = false
	_show_slide(slide_index)


func _replay_slide() -> void:
	if _phase == Phase.SLIDES and slide_index >= 0 and slide_index < slides.size():
		_show_slide(slide_index)


func _toggle_play() -> void:
	playing = not playing
	_play_button.text = "Pause" if playing else "Play"
	set_process(playing)


func _show_slide(index: int) -> void:
	_clear_slide_visuals()
	var slide: Dictionary = slides[index]
	_progress_label.text = "Slide %d / %d" % [index + 1, slides.size()]
	_narration.text = String(slide.get("narration", ""))
	_angel_mood.text = "Angel"
	_presenter.set_mood("neutral")
	_play_button.text = "Pause"
	playing = true
	set_process(true)
	_action_clock = 0.0
	_actions_done.clear()
	_visual.queue_redraw()
	_speak(String(slide.get("narration", "")))
	_maybe_ask_checkpoint()


func _process(delta: float) -> void:
	if not playing or _phase != Phase.SLIDES \
			or slide_index < 0 or slide_index >= slides.size():
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
	_actions_done.clear()
	_action_clock = 0.0
	_visual.queue_redraw()


func _apply_action(act: Dictionary) -> void:
	match String(act.get("action", "")):
		"show_caption":
			_spawn_label(_caption_box, String(act.get("text", "")),
				18, Color(0.98, 0.72, 0.25))
		"reveal_bullets":
			for item: Variant in (act.get("items", []) as Array):
				_spawn_label(_bullets_box, "\u2022 " + String(item),
					15, Color(0.9, 0.93, 1.0))
		"mark_point":
			_spawn_label(_caption_box, String(act.get("label", "")),
				12, Color(0.95, 0.96, 1.0))
			_visual.queue_redraw()
		"show_number_line", "highlight_interval":
			_visual.queue_redraw()


func _spawn_label(box: VBoxContainer, text: String, size: int, color: Color) -> void:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	box.add_child(label)
	label.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(label, "modulate:a", 1.0, 0.3)


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
	if _phase != Phase.SLIDES or slide_index < 0 or slide_index >= slides.size():
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
	var first := int(ceilf(v_from))
	var last := int(floorf(v_to))
	for v: int in range(first, last + 1):
		var tx := _value_to_x(float(v), v_from, v_to)
		_visual.draw_line(Vector2(tx, y - TICK_LEN * 0.6), Vector2(tx, y + TICK_LEN * 0.6),
			Color(0.6, 0.65, 0.8), LINE_THICKNESS * 0.6)
		_visual.draw_string(ThemeDB.fallback_font, Vector2(tx - 4.0, y + 22.0), str(v),
			HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.75, 0.78, 0.9))
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


# ------------------------------------------------------------ checkpoints

func _maybe_ask_checkpoint() -> void:
	var checkpoints: Array = slides[slide_index].get("checkpoints", [])
	if checkpoints.is_empty():
		_awaiting_checkpoint = {}
		return
	if slide_index < _checkpoint_done.size() and bool(_checkpoint_done[slide_index]):
		_awaiting_checkpoint = {}
		return
	while _checkpoint_done.size() <= slide_index:
		_checkpoint_done.append(false)
	var cp: Dictionary = checkpoints[0]
	_awaiting_checkpoint = cp
	_angel_mood.text = "Angel asks:"
	_presenter.set_mood("thinking")
	_speak(String(cp.get("question", "")))


# ------------------------------------------------------- input routing

func _on_send_pressed() -> void:
	var raw := _answer_edit.text
	_answer_edit.clear()
	if raw.strip_edges().is_empty():
		return
	if not _awaiting_checkpoint.is_empty():
		_handle_checkpoint_answer(raw)
	elif _phase == Phase.SLIDES:
		_handle_free_question(raw)
	elif _phase == Phase.PRACTICE:
		_handle_practice_input(raw)
	else:
		_angel_say("Pehle slides ya quiz finish karo — phir main sab kuch dobara samjha doongi!", "neutral")


func _handle_checkpoint_answer(raw: String) -> void:
	var result := _brain.check_checkpoint_answer(raw, _awaiting_checkpoint)
	var slide_idx := slide_index
	if bool(result["correct"]):
		_checkpoint_done[slide_idx] = true
		_awaiting_checkpoint = {}
	_angel_say(String(result["text"]), String(result["mood"]))


func _handle_free_question(raw: String) -> void:
	var reply := _brain.respond(raw, {
		"quiz_score": _quiz_correct,
		"last_wrong_topic_point": "",
		"wrong_streak": 0,
	})
	_angel_say(String(reply["text"]), String(reply["mood"]))


func _handle_practice_input(raw: String) -> void:
	var norm := raw.to_lower().strip_edges()
	if _practice_awaiting_selfcheck:
		_practice_awaiting_selfcheck = false
		if norm.begins_with("y") or norm.begins_with("haan") or norm.begins_with("han") \
				or norm.contains("yes") or norm.contains("match"):
			_practice_correct += 1
			_angel_say("Zabardast! Method matched. Chalo quiz ki taraf.", "happy")
		else:
			_angel_say("Koi baat nahi — solution upar parh lo, quiz mein yehi method aayega.", "thinking")
		_next_practice_or_quiz()
		return
	if _practice_index < _practice_items.size():
		var item: Dictionary = _practice_items[_practice_index]
		var solution := String(item.get("solution", ""))
		var citation := String(item.get("citation", ""))
		_narration.text = solution + ("  (" + citation + ")" if citation != "" else "")
		_speak(solution)
		_practice_awaiting_selfcheck = true
		_angel_say("Compare with your working — did your method match? Type yes or no.", "thinking")


func _next_practice_or_quiz() -> void:
	_practice_index += 1
	if _practice_index < _practice_items.size():
		_present_practice()
	else:
		_start_quiz()


# ------------------------------------------------------------- practice

func _start_practice() -> void:
	_phase = Phase.PRACTICE
	if _practice_items.is_empty():
		push_error("LessonPresentation: no scored practice item for %s" % topic_id)
		_angel_say("Practice data missing — is attempt ka score nahi ban sakta. Exit karke dobara koshish karo.", "neutral")
		return
	playing = false
	set_process(false)
	_progress_label.text = "Practice"
	_present_practice()


func _present_practice() -> void:
	var item: Dictionary = _practice_items[_practice_index]
	_narration.text = String(item.get("prompt", ""))
	_angel_mood.text = "Angel (practice)"
	_presenter.set_mood("thinking")
	_speak(String(item.get("prompt", "")))


# ---------------------------------------------------------------- quiz

func _start_quiz() -> void:
	if _quiz_data.size() != 3:
		push_error("LessonPresentation: expected 3 quiz questions, got %d" % _quiz_data.size())
		_angel_say("Quiz data incomplete — score nahi ban sakta. Exit karke dobara koshish karo.", "neutral")
		return
	_phase = Phase.QUIZ
	_quiz_index = 0
	_quiz_correct = 0
	_quiz_answered_first.clear()
	_quiz_panel.visible = true
	_slide_area.visible = false
	_controls_visible(false)
	_progress_label.text = "Quiz 1 / 3"
	_present_quiz_question()


func _controls_visible(on: bool) -> void:
	_back_button.visible = on
	_replay_button.visible = on
	_play_button.visible = on
	_next_button.visible = on


func _present_quiz_question() -> void:
	for child: Node in _choices_box.get_children():
		child.queue_free()
	_quiz_feedback.visible = false
	var q: Dictionary = _quiz_data[_quiz_index]
	_question_label.text = "Q%d. %s" % [_quiz_index + 1, String(q.get("text", ""))]
	var choices: Array = q.get("choices", [])
	for ci: int in choices.size():
		var btn := Button.new()
		btn.text = "%d. %s" % [ci + 1, String(choices[ci])]
		btn.custom_minimum_size = Vector2(0, 46)
		btn.add_theme_font_size_override("font_size", 14)
		btn.pressed.connect(_on_quiz_choice.bind(ci))
		_choices_box.add_child(btn)
	_angel_mood.text = "Angel (quiz)"
	_presenter.set_mood("thinking")


func _on_quiz_choice(choice: int) -> void:
	if _quiz_index >= _quiz_data.size():
		return
	var first := not _quiz_answered_first.has(_quiz_index)
	if first:
		_quiz_answered_first.append(_quiz_index)
	var q: Dictionary = _quiz_data[_quiz_index]
	var correct: bool = choice == int(q.get("correct_index", -1))
	if first and correct:
		_quiz_correct += 1
	if first:
		# Explanations only after submission; Angel reacts supportively.
		_quiz_feedback.text = ("Correct! " if correct else "Not quite. ") \
			+ String(q.get("explanation", ""))
		_quiz_feedback.visible = true
		_angel_say(("Sahi jawab! " if correct else "Arre! ") + String(q.get("explanation", "")),
			"excited" if correct else "thinking")
	var last := _quiz_index + 1 >= _quiz_data.size()
	_quiz_index += 1
	if last:
		_show_score()
	else:
		_progress_label.text = "Quiz %d / 3" % [_quiz_index + 1]
		_present_quiz_question()


# ---------------------------------------------------------------- score

func _show_score() -> void:
	var result := UnderstandingScorer.compute(
		_quiz_correct, _practice_correct, _practice_items.size())
	if not bool(result["ok"]):
		_angel_say("Scoring validation failed: " + String(result["error"]), "neutral")
		return
	_quiz_panel.visible = false
	_score_panel.visible = true
	_progress_label.text = "Result"
	var understanding := int(result["understanding_percent"])
	_score_value.text = "%d / 100" % understanding
	_score_detail.text = "Quiz %d/3 (%d%%) + Practice %d/%d (%d%%)  •  first answers only" % [
		_quiz_correct, int(result["quiz_percent"]),
		_practice_correct, _practice_items.size(), int(result["practice_percent"])]
	_score_next.text = UnderstandingScorer.next_step(understanding)
	_angel_mood.text = "Angel"
	_presenter.set_mood("excited" if understanding >= 80 else "happy")
	_persist_results(int(result["quiz_percent"]),
		int(result["practice_percent"]), understanding)
	_angel_say("Understanding this attempt: %d out of 100. %s" % [
		understanding, UnderstandingScorer.next_step(understanding)],
		"excited" if understanding >= 80 else "happy")


## Persists via the existing LearningProgress API: record_attempt counts the
## finished quiz once (XP rules stay idempotent), record_understanding stores
## the score components without touching attempt counts or rewards.
func _persist_results(quiz_percent: int, practice_percent: int,
		understanding: int) -> void:
	var progress := LearningProgress.new()
	progress.load_progress()
	progress.record_attempt(topic_id, _quiz_correct)
	progress.record_understanding(topic_id, quiz_percent, practice_percent, understanding)


# ------------------------------------------------------------ angel glue

func _angel_say(text: String, mood: String) -> void:
	_narration.text = text
	_angel_mood.text = "Angel"
	_presenter.set_mood(mood)
	_speak(text)


func _on_listen_pressed() -> void:
	# STT is optional and disabled (no verified plugin in this project):
	# typed input always works and the button explains that.
	_angel_say(_listen.status_text() + " Type your answer below and press Send.", "neutral")


func _speak(text: String) -> void:
	if voice_enabled:
		_voice.speak(text)
