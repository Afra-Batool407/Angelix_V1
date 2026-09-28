extends Control
## Angelix lesson view — the offline MVP learning workflow for one topic.
##
## Flow: explanation -> animated number-line timeline -> guided practice ->
## 3-question quiz -> feedback -> saved mastery. The Angel companion answers
## chat input offline via AngelBrain. All content comes from
## res://content/topics/math.u01.real-numbers.json — nothing is hard-coded here.
##
## Android back returns to the menu (NOTIFICATION_WM_GO_BACK_REQUEST plus the
## on-screen Back button).

const MENU_SCENE := "res://scenes/ui_menu.tscn"
const DEFAULT_TOPIC_PATH := "res://content/topics/math.u01.real-numbers.json"
const EXPECTED_TOPIC_ID := "math.u01.real-numbers"

const COL_BG := Color(0.039, 0.055, 0.102)
const COL_PANEL := Color(0.09, 0.11, 0.19)
const COL_PANEL_LIGHT := Color(0.13, 0.16, 0.27)
const COL_ACCENT := Color(0.98, 0.72, 0.25)
const COL_TEXT := Color(0.93, 0.95, 1.0)
const COL_MUTED := Color(0.62, 0.67, 0.82)
const COL_GOOD := Color(0.30, 0.85, 0.60)
const COL_BAD := Color(0.95, 0.42, 0.42)

## When true (embedded as the world's lesson overlay), the lesson hides its
## own back button and ignores back navigation; the world controller owns
## closing the overlay and handling the Android back key. Standalone use
## (menu fallback route) keeps the old behavior.
var overlay_mode := false
## Optional override of the topic JSON path (set by the world controller for
## a specific station's topic; standalone route uses the default topic).
var topic_path_override := ""

var topic_data := {}
var _brain: AngelBrain
var _progress := LearningProgress.new()

var _learn_box: VBoxContainer
var _practice_box: VBoxContainer
var _quiz_box: VBoxContainer
var _result_box: VBoxContainer
var _timeline: LessonRenderer

var _quiz_index := 0
var _quiz_correct := 0
var _quiz_answers := {}    # question id -> chosen index
var _wrong_streak := 0
var _last_wrong_point := ""

@onready var _title_label: Label = %TitleLabel
@onready var _back_button: Button = %BackButton
@onready var _content_stack: VBoxContainer = %ContentStack
@onready var _angel_panel: Panel = %AngelPanel
@onready var _angel_mood_label: Label = %AngelMoodLabel
@onready var _angel_text: RichTextLabel = %AngelText
@onready var _chat_edit: LineEdit = %ChatEdit
@onready var _send_button: Button = %SendButton


func _ready() -> void:
	_progress.load_progress()
	var path := topic_path_override if topic_path_override != "" else DEFAULT_TOPIC_PATH
	_load_topic(path)
	if topic_data.is_empty():
		_show_error_screen("Lesson content could not be loaded. Please reopen the topic from the menu.")
		return
	_build_ui()
	_apply_section(0)
	if _timeline != null:
		_timeline.play()
	_angel_say(
		"Assalam-o-Alaikum! Main Angel hoon. Chalo %s seekhte hain!"
		% String(topic_data.get("title", "Real Numbers")), "happy")


func _load_topic(path: String) -> void:
	if not FileAccess.file_exists(path):
		push_error("Lesson: topic file missing: %s" % path)
		topic_data = {}
		return
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_error("Lesson: cannot open %s" % path)
		topic_data = {}
		return
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if not (parsed is Dictionary):
		push_error("Lesson: topic JSON malformed: %s" % path)
		topic_data = {}
		return
	var data: Dictionary = parsed
	var tid := String(data.get("topic_id", ""))
	if topic_path_override == "" and tid != EXPECTED_TOPIC_ID:
		push_error("Lesson: unexpected topic_id '%s' — refusing to render." % tid)
		topic_data = {}
		return
	if topic_path_override != "" and tid.is_empty():
		push_error("Lesson: override content has no topic_id — refusing to render.")
		topic_data = {}
		return
	if String(data.get("explanation", "")).is_empty():
		push_error("Lesson: topic has no explanation — refusing to render.")
		topic_data = {}
		return
	topic_data = data
	_brain = AngelBrain.new()
	_brain.setup(topic_data)


# ---------------------------------------------------------------- UI build

func _build_ui() -> void:
	_title_label.text = String(topic_data.get("title", "Lesson"))
	_back_button.visible = not overlay_mode
	if not overlay_mode and not _back_button.pressed.is_connected(_go_back):
		_back_button.pressed.connect(_go_back)
	if not _send_button.pressed.is_connected(_on_send_pressed):
		_send_button.pressed.connect(_on_send_pressed)
	if not _chat_edit.text_submitted.is_connected(_on_chat_submitted):
		_chat_edit.text_submitted.connect(_on_chat_submitted)

	# Section switcher tabs.
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 8)
	var names := ["Learn", "Practice", "Quiz"]
	for i in names.size():
		var b := Button.new()
		b.text = names[i]
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(0, 40)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(_apply_section.bind(i))
		tabs.add_child(b)
	_content_stack.add_child(tabs)

	# --- Learn section ---
	_learn_box = VBoxContainer.new()
	_learn_box.name = "LearnBox"
	_learn_box.add_theme_constant_override("separation", 10)

	var expl_panel := _panel()
	var expl_text := RichTextLabel.new()
	expl_text.fit_content = true
	expl_text.text = String(topic_data.get("explanation", ""))
	expl_text.add_theme_font_size_override("normal_font_size", 16)
	expl_text.add_theme_color_override("default_color", COL_TEXT)
	expl_text.custom_minimum_size = Vector2(0, 80)
	expl_panel.add_child(expl_text)
	_learn_box.add_child(expl_panel)

	var life_panel := _panel()
	life_panel.add_child(_accent_head("Daily life (Pakistan)"))
	var life_text := RichTextLabel.new()
	life_text.fit_content = true
	life_text.text = String(topic_data.get("pakistani_life_example", ""))
	life_text.add_theme_font_size_override("normal_font_size", 15)
	life_text.add_theme_color_override("default_color", COL_TEXT)
	life_text.custom_minimum_size = Vector2(0, 60)
	life_panel.add_child(life_text)
	_learn_box.add_child(life_panel)

	var anim_panel := _panel()
	var anim_title := String(topic_data.get("teaching_animation", {}).get("title", "Animation"))
	anim_panel.add_child(_accent_head("Watch: " + anim_title))
	anim_panel.add_child(_build_timeline_holder())
	anim_panel.add_child(_build_timeline_controls())
	_learn_box.add_child(anim_panel)

	var we: Dictionary = topic_data.get("worked_example", {})
	if not we.is_empty():
		var we_panel := _panel()
		we_panel.add_child(_accent_head("Worked example: " + String(we.get("title", ""))))
		var we_text := RichTextLabel.new()
		we_text.fit_content = true
		var lines := ""
		var steps: Array = we.get("steps", [])
		for i in steps.size():
			lines += "%d. %s\n" % [i + 1, String(steps[i])]
		lines += "\nAnswer: " + String(we.get("answer", ""))
		we_text.text = lines
		we_text.add_theme_font_size_override("normal_font_size", 15)
		we_text.add_theme_color_override("default_color", COL_TEXT)
		we_panel.add_child(we_text)
		var cite := Label.new()
		cite.text = "Source: " + String(we.get("citation", ""))
		cite.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		cite.add_theme_font_size_override("font_size", 12)
		cite.add_theme_color_override("font_color", COL_MUTED)
		we_panel.add_child(cite)
		_learn_box.add_child(we_panel)

	_content_stack.add_child(_learn_box)

	# --- Practice section ---
	_practice_box = VBoxContainer.new()
	_practice_box.name = "PracticeBox"
	_practice_box.add_theme_constant_override("separation", 10)
	var practice_items: Array = topic_data.get("practice", [])
	for item in practice_items:
		if item is Dictionary:
			_practice_box.add_child(_build_practice_item(item))
	if practice_items.is_empty():
		_practice_box.add_child(_muted_label("No practice items for this topic yet."))
	_content_stack.add_child(_practice_box)

	# --- Quiz section ---
	_quiz_box = VBoxContainer.new()
	_quiz_box.name = "QuizBox"
	_quiz_box.add_theme_constant_override("separation", 10)
	_content_stack.add_child(_quiz_box)

	# --- Result section ---
	_result_box = VBoxContainer.new()
	_result_box.name = "ResultBox"
	_result_box.add_theme_constant_override("separation", 10)
	_content_stack.add_child(_result_box)


func _build_timeline_holder() -> Control:
	var holder := PanelContainer.new()
	holder.custom_minimum_size = Vector2(0, 240)
	var holder_style := StyleBoxFlat.new()
	holder_style.bg_color = Color(0.05, 0.07, 0.13)
	holder_style.set_corner_radius_all(12)
	holder.add_theme_stylebox_override("panel", holder_style)
	_timeline = LessonRenderer.new()
	_timeline.custom_minimum_size = Vector2(0, 220)
	_timeline.size_flags_vertical = Control.SIZE_EXPAND_FILL
	holder.add_child(_timeline)
	var steps: Array = topic_data.get("teaching_animation", {}).get("steps", [])
	# setup() only validates data, safe before _ready(); play() needs the node
	# in the tree, so it is called from _ready() after the UI is built.
	_timeline.setup(steps)
	return holder


func _build_timeline_controls() -> Control:
	var controls := HBoxContainer.new()
	controls.add_theme_constant_override("separation", 8)

	var play_btn := Button.new()
	play_btn.text = "Replay"
	play_btn.pressed.connect(func() -> void:
		if _timeline != null:
			_timeline.play())
	controls.add_child(play_btn)

	var pause_btn := Button.new()
	pause_btn.text = "Pause / Resume"
	pause_btn.pressed.connect(func() -> void:
		if _timeline == null:
			return
		if _timeline.is_playing():
			_timeline.pause()
		else:
			_timeline.resume())
	controls.add_child(pause_btn)

	var step_btn := Button.new()
	step_btn.text = "Step >"
	step_btn.pressed.connect(func() -> void:
		if _timeline != null:
			_timeline.step_forward())
	controls.add_child(step_btn)
	return controls


func _panel() -> PanelContainer:
	var p := PanelContainer.new()
	var st := StyleBoxFlat.new()
	st.bg_color = COL_PANEL
	st.set_corner_radius_all(14)
	st.content_margin_left = 14.0
	st.content_margin_right = 14.0
	st.content_margin_top = 12.0
	st.content_margin_bottom = 12.0
	p.add_theme_stylebox_override("panel", st)
	return p


func _accent_head(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", 15)
	l.add_theme_color_override("font_color", COL_ACCENT)
	return l


func _muted_label(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_color_override("font_color", COL_MUTED)
	return l


func _build_practice_item(item: Dictionary) -> Control:
	var panel := _panel()
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	panel.add_child(v)

	var q := Label.new()
	q.text = String(item.get("prompt", ""))
	q.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	q.add_theme_font_size_override("font_size", 16)
	v.add_child(q)

	var reveal := Button.new()
	reveal.text = "Show hint"
	v.add_child(reveal)

	var hint := Label.new()
	hint.text = "Hint: " + String(item.get("hint", ""))
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_color_override("font_color", COL_ACCENT)
	hint.visible = false
	v.add_child(hint)

	var sol_btn := Button.new()
	sol_btn.text = "Show solution"
	sol_btn.visible = false
	v.add_child(sol_btn)

	var sol := Label.new()
	sol.text = String(item.get("solution", ""))
	sol.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sol.add_theme_color_override("font_color", COL_GOOD)
	sol.visible = false
	v.add_child(sol)

	var cite := Label.new()
	cite.text = "Source: " + String(item.get("citation", ""))
	cite.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	cite.add_theme_font_size_override("font_size", 12)
	cite.add_theme_color_override("font_color", COL_MUTED)
	v.add_child(cite)

	reveal.pressed.connect(func() -> void:
		hint.visible = true
		sol_btn.visible = true
		reveal.disabled = true)
	sol_btn.pressed.connect(func() -> void:
		sol.visible = true
		sol_btn.disabled = true)
	return panel


func _show_error_screen(message: String) -> void:
	_title_label.text = "Lesson"
	var lbl := Label.new()
	lbl.text = message
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.add_theme_color_override("font_color", COL_MUTED)
	_content_stack.add_child(lbl)


# ------------------------------------------------------------ section flow

func _apply_section(idx: int) -> void:
	if _learn_box != null:
		_learn_box.visible = idx == 0
	if _practice_box != null:
		_practice_box.visible = idx == 1
	if _quiz_box != null:
		_quiz_box.visible = idx == 2
	if _result_box != null:
		_result_box.visible = idx == 3
	if idx == 2:
		_start_quiz()


# ------------------------------------------------------------------- quiz

func _start_quiz() -> void:
	_quiz_index = 0
	_quiz_correct = 0
	_quiz_answers.clear()
	_render_quiz_question()


func _render_quiz_question() -> void:
	for c in _quiz_box.get_children():
		c.queue_free()

	var questions: Array = topic_data.get("quiz", [])
	if questions.is_empty() or _quiz_index >= questions.size():
		_finish_quiz()
		return
	var q: Dictionary = questions[_quiz_index]

	var head := Label.new()
	head.text = "Question %d of %d" % [_quiz_index + 1, questions.size()]
	head.add_theme_color_override("font_color", COL_MUTED)
	_quiz_box.add_child(head)

	var panel := _panel()
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	panel.add_child(v)

	var text := Label.new()
	text.text = String(q.get("text", ""))
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.add_theme_font_size_override("font_size", 17)
	v.add_child(text)

	var choices: Array = q.get("choices", [])
	for ci in choices.size():
		var btn := Button.new()
		btn.text = String(choices[ci])
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		btn.custom_minimum_size = Vector2(0, 44)
		btn.focus_mode = Control.FOCUS_NONE
		btn.pressed.connect(_on_quiz_choice.bind(ci))
		v.add_child(btn)

	var status := Label.new()
	status.add_theme_color_override("font_color", COL_MUTED)
	status.text = "Pick one answer. The correct answer is shown after the quiz."
	_quiz_box.add_child(status)
	_quiz_box.add_child(panel)


func _on_quiz_choice(choice_idx: int) -> void:
	var questions: Array = topic_data.get("quiz", [])
	if _quiz_index >= questions.size():
		return
	var q: Dictionary = questions[_quiz_index]
	var qid := String(q.get("id", "q%d" % _quiz_index))
	_quiz_answers[qid] = choice_idx
	var correct := choice_idx == int(q.get("correct_index", -1))
	if correct:
		_quiz_correct += 1
		_wrong_streak = 0
	else:
		_wrong_streak += 1
		_last_wrong_point = _wrong_point_from_question(q)

	_quiz_index += 1
	if _quiz_index < questions.size():
		_render_quiz_question()
	else:
		_finish_quiz()


func _wrong_point_from_question(q: Dictionary) -> String:
	var qid := String(q.get("id", ""))
	if qid.contains("rational-decimal"):
		return "terminating vs irrational decimals"
	if qid.contains("recurring-to-fraction"):
		return "recurring decimal to p/q form"
	if qid.contains("sqrt5-location"):
		return "sqrt(5) triangle construction"
	return ""


func _finish_quiz() -> void:
	var total: int = topic_data.get("quiz", []).size()
	if total == 0:
		for c in _result_box.get_children():
			c.queue_free()
		_result_box.add_child(_muted_label("Quiz is not available for this topic."))
		_apply_section(3)
		return
	var entry := _progress.record_attempt(String(topic_data.get("topic_id", EXPECTED_TOPIC_ID)), _quiz_correct)
	_render_result(_quiz_correct, total, entry)
	_apply_section(3)


func _render_result(score: int, total: int, entry: Dictionary) -> void:
	for c in _result_box.get_children():
		c.queue_free()

	var headline := Label.new()
	headline.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if score == total:
		headline.text = "Mastery! %d / %d — Shabash!" % [score, total]
	elif score >= total - 1:
		headline.text = "%d / %d — almost there! Practice once more?" % [score, total]
	else:
		headline.text = "%d / %d — let's review together." % [score, total]
	headline.add_theme_font_size_override("font_size", 22)
	_result_box.add_child(headline)

	var detail := _muted_label(
		"Attempts: %d   Best: %d/%d%s" % [
			int(entry.get("attempt_count", 0)),
			int(entry.get("best_score", 0)), total,
			"   MASTERED" if bool(entry.get("mastered", false)) else ""])
	_result_box.add_child(detail)

	# Per-question feedback with explanations (only after the quiz ends).
	var questions: Array = topic_data.get("quiz", [])
	for q in questions:
		if not (q is Dictionary):
			continue
		var qd: Dictionary = q
		var qid := String(qd.get("id", ""))
		var chosen: int = int(_quiz_answers.get(qid, -1))
		var ok := chosen == int(qd.get("correct_index", -1))
		var line := Label.new()
		line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		line.text = "%s %s\n%s" % [
			"Correct!" if ok else "Not quite:",
			String(qd.get("text", "")), String(qd.get("explanation", ""))]
		line.add_theme_color_override("font_color", COL_GOOD if ok else COL_BAD)
		_result_box.add_child(line)

	# 0-1 of 3: show a supportive hint and the worked example before retry.
	if score <= total - 2:
		var review := _panel()
		review.add_child(_accent_head("Review before you retry"))
		var practices: Array = topic_data.get("practice", [])
		if not practices.is_empty() and practices[0] is Dictionary:
			var hint_lbl := Label.new()
			hint_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			hint_lbl.text = "Hint: " + String(practices[0].get("hint", ""))
			hint_lbl.add_theme_color_override("font_color", COL_ACCENT)
			review.add_child(hint_lbl)
		var wex: Dictionary = topic_data.get("worked_example", {})
		if not wex.is_empty():
			var we_lbl := Label.new()
			we_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			we_lbl.text = "Worked example (%s): %s" % [
				String(wex.get("title", "")), String(wex.get("answer", ""))]
			review.add_child(we_lbl)
		_result_box.add_child(review)

	var again := Button.new()
	again.text = "Try again"
	again.pressed.connect(func() -> void: _apply_section(2))
	_result_box.add_child(again)

	var to_practice := Button.new()
	to_practice.text = "Back to practice"
	to_practice.pressed.connect(func() -> void: _apply_section(1))
	_result_box.add_child(to_practice)

	# Angel reacts using quiz context (offline, from AngelBrain fallbacks).
	if _brain != null:
		var intent := "encouragement" if score >= total - 1 else "why_wrong"
		var reply := _brain.respond(intent, {
			"quiz_score": score,
			"last_wrong_topic_point": _last_wrong_point,
		})
		_angel_say(String(reply["text"]), String(reply["mood"]))


# ------------------------------------------------------------------ angel

func _angel_say(text: String, mood: String) -> void:
	if not is_instance_valid(_angel_text):
		return
	_angel_text.text = text
	_angel_mood_label.text = "Angel — " + mood
	_apply_angel_mood(mood)


## Mood -> verified procedural Angel visual states. The imported Angel model
## has NO AnimationPlayer clips (checked scenes/angel.tscn); moods map onto
## the procedural parameters that exist in scripts/angel.gd (wing flap speed,
## glow energy, bob amplitude) plus a panel accent color here. Unknown moods
## fall back to "neutral".
func _apply_angel_mood(mood: String) -> void:
	var safe := mood if mood in AngelBrain.MOODS else "neutral"
	var col := Color(0.62, 0.67, 0.82)
	match safe:
		"happy":
			col = COL_GOOD
		"excited":
			col = COL_ACCENT
		"thinking":
			col = Color(0.55, 0.75, 1.0)
		_:
			col = Color(0.62, 0.67, 0.82)
	var style := StyleBoxFlat.new()
	style.bg_color = COL_PANEL_LIGHT
	style.set_corner_radius_all(14)
	style.border_color = col
	style.set_border_width_all(2)
	style.content_margin_left = 12.0
	style.content_margin_right = 12.0
	style.content_margin_top = 10.0
	style.content_margin_bottom = 10.0
	_angel_panel.add_theme_stylebox_override("panel", style)


func _on_send_pressed() -> void:
	var raw := _chat_edit.text.strip_edges()
	if raw.is_empty():
		return
	_chat_edit.clear()
	_handle_chat(raw)


func _on_chat_submitted(text: String) -> void:
	var raw := text.strip_edges()
	if raw.is_empty():
		return
	_chat_edit.clear()
	_handle_chat(raw)


func _handle_chat(raw: String) -> void:
	if _brain == null:
		return
	var reply := _brain.respond(raw, {
		"quiz_score": _quiz_correct,
		"last_wrong_topic_point": _last_wrong_point,
		"wrong_streak": _wrong_streak,
	})
	_angel_say(String(reply["text"]), String(reply["mood"]))


# ------------------------------------------------------------- navigation

func _go_back() -> void:
	get_tree().change_scene_to_file(MENU_SCENE)


func _notification(what: int) -> void:
	if overlay_mode:
		return  # the world controller owns back handling for the overlay
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_go_back()


func _unhandled_input(event: InputEvent) -> void:
	if overlay_mode:
		return  # the world controller owns back handling for the overlay
	# Android hardware back key maps to ui_cancel by default in Godot 4.
	if event.is_action_pressed("ui_cancel"):
		_go_back()
