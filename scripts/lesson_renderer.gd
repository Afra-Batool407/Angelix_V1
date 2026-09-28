extends Control
class_name LessonRenderer
## Offline teaching-timeline renderer for the Angelix lesson view.
##
## Reads the `teaching_animation.steps` array from a topic JSON and plays it
## on a drawn number line using only local Godot nodes and tweens (no video,
## no network, no external assets).
##
## Allowed actions (validated):
##   show_number_line   — draws/animates the line, ticks -4..4
##   mark_point         — value, label, kind ("rational"|"irrational"), caption
##   highlight_interval — from, to, label, caption
##   show_caption       — caption only
##
## Validation contract: on invalid step data this node logs a useful error to
## the Godot Output (push_error), skips the bad step, and keeps the lesson
## playable — it never crashes and never leaves a broken frame.

signal timeline_finished

const STEP_HOLD := 2.6          ## seconds a step stays visible before advancing
const TWEEN_TIME := 0.6         ## seconds each element animates in
const MIN_VALUE := -4.0         ## clamp for mark_point values
const MAX_VALUE := 4.0

const COL_RATIONAL := Color(0.30, 0.85, 0.60)
const COL_IRRATIONAL := Color(1.00, 0.72, 0.25)
const COL_INTERVAL := Color(0.45, 0.65, 1.00, 0.35)
const COL_LINE := Color(0.75, 0.80, 0.95)
const COL_TICK_TEXT := Color(0.60, 0.65, 0.82)
const COL_CAPTION := Color(0.95, 0.96, 1.0)

const KIND_RATIONAL := "rational"
const KIND_IRRATIONAL := "irrational"

var _steps: Array = []
var _valid_steps: Array = []
var _step_index := -1
var _playing := false
var _step_timer: Timer
var _caption_label: Label
var _progress_label: Label
var _draw_root: Control

## Populated as steps play; used to reset the board on replay.
var _spawned: Array = []

var _line_y := 0.0
var _line_x0 := 0.0
var _line_x1 := 0.0
var _line_unit := 0.0
var _board_size := Vector2.ZERO


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP

	_draw_root = Control.new()
	_draw_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_draw_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_draw_root.draw.connect(_on_draw_root_draw)
	add_child(_draw_root)

	_caption_label = Label.new()
	_caption_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_caption_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_caption_label.add_theme_font_size_override("font_size", 16)
	_caption_label.add_theme_color_override("font_color", COL_CAPTION)
	_caption_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_caption_label.offset_left = 12.0
	_caption_label.offset_right = -12.0
	_caption_label.offset_bottom = -10.0
	_caption_label.offset_top = -64.0
	_caption_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_caption_label)

	_progress_label = Label.new()
	_progress_label.add_theme_font_size_override("font_size", 13)
	_progress_label.add_theme_color_override("font_color", Color(0.55, 0.6, 0.78))
	_progress_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	_progress_label.offset_left = 10.0
	_progress_label.offset_top = 8.0
	_progress_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_progress_label)

	_step_timer = Timer.new()
	_step_timer.one_shot = true
	_step_timer.timeout.connect(_advance_step)
	add_child(_step_timer)


func setup(steps: Array) -> void:
	_steps = steps
	_valid_steps = []
	for i in steps.size():
		var step: Variant = steps[i]
		var err := _validate_step(step, i)
		if err == "":
			_valid_steps.append(step)
		else:
			push_error("Timeline step %d invalid: %s" % [i + 1, err])
	if _valid_steps.is_empty() and not steps.is_empty():
		push_error("Timeline has %d steps and none are valid; using safe fallback." % steps.size())
		_valid_steps = _fallback_steps()
	elif _valid_steps.is_empty():
		_valid_steps = _fallback_steps()


func _fallback_steps() -> Array:
	return [
		{
			"order": 1,
			"action": "show_number_line",
			"caption": "The real number line (safe fallback — timeline data was invalid).",
		},
		{
			"order": 2,
			"action": "show_caption",
			"caption": "Open the topic JSON and fix the teaching_animation steps.",
		},
	]


## Validates one step. Returns "" when valid, otherwise a human-readable error.
func _validate_step(step: Variant, _index: int) -> String:
	if not (step is Dictionary):
		return "step is not a Dictionary"
	var d: Dictionary = step
	var action := String(d.get("action", ""))
	var required: Array
	match action:
		"show_number_line":
			required = []
		"mark_point":
			required = ["value"]
		"highlight_interval":
			required = ["from", "to"]
		"show_caption":
			required = []
		_:
			return "unknown action '%s'" % action

	for key in required:
		if not d.has(key):
			return "missing field '%s' for action '%s'" % [key, action]
		if key in ["value", "from", "to"]:
			var v: Variant = d[key]
			if not (v is float or v is int):
				return "field '%s' must be a number" % key

	if action == "mark_point":
		var pv: float = float(d["value"])
		if is_nan(pv) or is_inf(pv):
			return "value must be finite"
		if pv < MIN_VALUE or pv > MAX_VALUE:
			return "value %s outside [%s, %s]" % [pv, MIN_VALUE, MAX_VALUE]
	return ""


func play() -> void:
	if _valid_steps.is_empty():
		_valid_steps = _fallback_steps()
	_board_reset()
	_step_index = -1
	_playing = true
	_advance_step()


func pause() -> void:
	_playing = false
	_step_timer.stop()


func resume() -> void:
	if _playing:
		return
	_playing = true
	if _step_index >= 0 and _step_index < _valid_steps.size():
		_step_timer.start(STEP_HOLD)
	else:
		_advance_step()


func is_playing() -> bool:
	return _playing


func has_steps() -> bool:
	return not _valid_steps.is_empty()


## Jumps to the next step immediately (used by the Step button).
func step_forward() -> void:
	_step_timer.stop()
	_playing = true
	_advance_step()


func _advance_step() -> void:
	_step_index += 1
	if _step_index >= _valid_steps.size():
		_playing = false
		timeline_finished.emit()
		return
	var step: Dictionary = _valid_steps[_step_index]
	_apply_step(step, _step_index)
	if _progress_label != null:
		_progress_label.text = "Step %d / %d" % [_step_index + 1, _valid_steps.size()]
	if _playing:
		_step_timer.start(STEP_HOLD)


func _apply_step(step: Dictionary, index: int) -> void:
	var action := String(step.get("action", ""))
	match action:
		"show_number_line":
			_board_reset()
			_ensure_line_metrics()
			_show_caption_text(String(step.get("caption", "")))
		"mark_point":
			_ensure_line_metrics()
			var v := float(step.get("value", 0.0))
			var kind := String(step.get("kind", "rational"))
			_spawn_point(v, String(step.get("label", "")), kind)
			_show_caption_text(String(step.get("caption", "")))
		"highlight_interval":
			_ensure_line_metrics()
			var from_v := float(step.get("from", 0.0))
			var to_v := float(step.get("to", 0.0))
			_spawn_interval(from_v, to_v, String(step.get("label", "")))
			_show_caption_text(String(step.get("caption", "")))
		"show_caption":
			_show_caption_text(String(step.get("caption", "")))


func _board_reset() -> void:
	if _draw_root == null:
		return
	for node in _spawned:
		if is_instance_valid(node):
			node.queue_free()
	_spawned.clear()
	_ensure_line_metrics()
	_draw_root.queue_redraw()


func _ensure_line_metrics() -> void:
	if _draw_root == null:
		return  # not yet in the tree; metrics are computed on first real step
	_board_size = _draw_root.size
	if _board_size.x <= 1.0:
		_board_size.x = 640.0
	if _board_size.y <= 1.0:
		_board_size.y = 220.0
	_line_y = _board_size.y * 0.52
	_line_x0 = 24.0
	_line_x1 = _board_size.x - 24.0
	var span := _line_x1 - _line_x0
	_line_unit = span / 9.0  # ticks from -4 .. +4


func _on_draw_root_draw() -> void:
	if _line_unit <= 0.0:
		return
	# Line + arrowheads
	_draw_root.draw_line(
		Vector2(_line_x0, _line_y), Vector2(_line_x1, _line_y), COL_LINE, 3.0, true)
	_draw_root.draw_line(
		Vector2(_line_x1, _line_y), Vector2(_line_x1 - 10.0, _line_y - 7.0), COL_LINE, 3.0, true)
	_draw_root.draw_line(
		Vector2(_line_x1, _line_y), Vector2(_line_x1 - 10.0, _line_y + 7.0), COL_LINE, 3.0, true)
	# Ticks and numbers -4..4
	for n in range(-4, 5):
		var x := _value_to_x(float(n))
		_draw_root.draw_line(
			Vector2(x, _line_y - 8.0), Vector2(x, _line_y + 8.0), COL_LINE, 2.0, true)
		var txt := str(n)
		_draw_root.draw_string(
			ThemeDB.fallback_font, Vector2(x - 8.0, _line_y + 30.0), txt,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 14, COL_TICK_TEXT)


func _value_to_x(value: float) -> float:
	return _line_x0 + (value + 4.0) * _line_unit


func _show_caption_text(text: String) -> void:
	if _caption_label == null:
		return  # not yet in the tree; play() is a no-op until ready
	var tw := create_tween()
	tw.tween_property(_caption_label, "modulate:a", 0.0, 0.12)
	tw.tween_callback(func() -> void: _caption_label.text = text)
	tw.tween_property(_caption_label, "modulate:a", 1.0, 0.25)


func _spawn_point(value: float, label: String, kind: String) -> void:
	if _draw_root == null:
		return
	var v := clampf(value, MIN_VALUE, MAX_VALUE)
	var col := COL_RATIONAL if kind == KIND_RATIONAL else COL_IRRATIONAL
	var x := _value_to_x(v)

	var dot := Panel.new()
	var dot_style := StyleBoxFlat.new()
	dot_style.bg_color = col
	dot_style.set_corner_radius_all(9)
	dot.add_theme_stylebox_override("panel", dot_style)
	dot.custom_minimum_size = Vector2(18, 18)
	dot.size = Vector2(18, 18)
	dot.position = Vector2(x - 9.0, _line_y - 9.0)
	dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dot.pivot_offset = Vector2(9, 9)
	_draw_root.add_child(dot)
	_spawned.append(dot)

	var dot_tw := dot.create_tween()
	dot_tw.tween_property(dot, "scale", Vector2.ONE, TWEEN_TIME) \
		.from(Vector2(0.2, 0.2)).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	if label != "":
		var lbl := Label.new()
		lbl.text = label
		lbl.add_theme_font_size_override("font_size", 14)
		lbl.add_theme_color_override("font_color", col)
		lbl.position = Vector2(x - 18.0, _line_y - 42.0)
		lbl.custom_minimum_size = Vector2(36, 0)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_draw_root.add_child(lbl)
		_spawned.append(lbl)
		var lbl_tw := lbl.create_tween()
		lbl_tw.tween_property(lbl, "position:y", _line_y - 38.0, TWEEN_TIME) \
			.from(_line_y - 30.0).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func _spawn_interval(from_v: float, to_v: float, label: String) -> void:
	if _draw_root == null:
		return
	var a := clampf(minf(from_v, to_v), MIN_VALUE, MAX_VALUE)
	var b := clampf(maxf(from_v, to_v), MIN_VALUE, MAX_VALUE)
	var x0 := _value_to_x(a)
	var x1 := _value_to_x(b)

	var band := ColorRect.new()
	band.color = COL_INTERVAL
	band.position = Vector2(x0, _line_y - 26.0)
	band.size = Vector2(x1 - x0, 52.0)
	band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_draw_root.add_child(band)
	_spawned.append(band)
	var band_tw := band.create_tween()
	band_tw.tween_property(band, "modulate:a", 1.0, TWEEN_TIME).from(0.0)

	if label != "":
		var lbl := Label.new()
		lbl.text = label
		lbl.add_theme_font_size_override("font_size", 14)
		lbl.add_theme_color_override("font_color", Color(0.85, 0.9, 1.0))
		lbl.position = Vector2((x0 + x1) * 0.5 - 24.0, _line_y - 58.0)
		lbl.custom_minimum_size = Vector2(48, 0)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_draw_root.add_child(lbl)
		_spawned.append(lbl)
		var lbl_tw := lbl.create_tween()
		lbl_tw.tween_property(lbl, "position:y", _line_y - 54.0, TWEEN_TIME) \
			.from(_line_y - 48.0).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
