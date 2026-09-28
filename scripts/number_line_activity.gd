extends Node3D
class_name NumberLineActivity
## In-world Real Numbers activity at the Math Meadows station.
##
## Builds a world-space number line (bar, ticks, labels, marker, result dots,
## quiz orbs) purely from a topic JSON's optional `world_activity` section —
## no scene editing needed for future topics. All geometry is low-poly Godot
## primitives; no navigation and no extra physics bodies beyond orb triggers.
##
## Validation contract: malformed or missing activity data never crashes —
## the node logs a useful error to the Godot Output and shows a safe fallback
## (a plain line with a "content unavailable" note).

signal activity_completed
signal open_lesson_requested
signal task_changed(prompt: String)

const ORB_SCENE := "res://scenes/quiz_orb.tscn"

const COL_BAR := Color(0.85, 0.9, 1.0)
const COL_TICK := Color(0.6, 0.68, 0.9)
const COL_RATIONAL := Color(0.3, 0.85, 0.6)
const COL_IRRATIONAL := Color(1.0, 0.72, 0.25)
const COL_MARKER := Color(1.0, 0.45, 0.45)
const COL_ORB_OK := Color(0.4, 0.9, 0.6)
const COL_ORB_BAD := Color(0.95, 0.45, 0.45)

@export var marker_step := 0.25  ## marker movement per tap (touch-friendly)

var _cfg := {}
var _marker_tasks: Array = []
var _task_index := -1
var _marker_value := 0.0
var _tasks_done := 0

var _spawned: Array = []
var _line_x0 := 0.0
var _line_x1 := 0.0

@onready var _status: Label3D = $Status

var _marker: Node3D
var _marker_label: Label3D


func _ready() -> void:
	# Safe defaults; setup() replaces them from JSON.
	_line_x0 = -6.0
	_line_x1 = 6.0


## cfg: the parsed `world_activity` Dictionary (may be empty/invalid).
func setup(cfg: Variant) -> void:
	_cfg = {}
	_marker_tasks = []
	if not (cfg is Dictionary):
		if cfg != null:
			push_error("NumberLineActivity: world_activity is not a Dictionary; using fallback.")
		_build_fallback()
		return
	var d: Dictionary = cfg
	var nl: Variant = d.get("number_line", {})
	if not (nl is Dictionary):
		push_error("NumberLineActivity: number_line section invalid; using fallback.")
		_build_fallback()
		return
	var nld: Dictionary = nl
	var mn := float(nld.get("min_value", -4.0))
	var mx := float(nld.get("max_value", 4.0))
	if is_nan(mn) or is_nan(mx) or not (mn < mx) or absf(mn) > 100.0 or absf(mx) > 100.0:
		push_error("NumberLineActivity: number_line range invalid (%s..%s); using fallback." % [mn, mx])
		_build_fallback()
		return
	var tasks: Variant = d.get("marker_tasks", [])
	if tasks is Array:
		for t in tasks:
			if t is Dictionary and _valid_task(t):
				_marker_tasks.append(t)
			else:
				push_error("NumberLineActivity: invalid marker task skipped: %s" % str(t))
	if _marker_tasks.is_empty():
		push_error("NumberLineActivity: no valid marker tasks; using fallback tasks.")
		_marker_tasks = _fallback_tasks()
	_cfg = d
	_rebuild()


func _valid_task(t: Dictionary) -> bool:
	var v: Variant = t.get("target_value")
	if not (v is float or v is int):
		return false
	var tol: Variant = t.get("tolerance", 0.2)
	if not (tol is float or tol is int) or float(tol) <= 0.0:
		return false
	return String(t.get("id", "")) != "" and String(t.get("prompt", "")) != ""


func _fallback_tasks() -> Array:
	return [{
		"id": "activity.task.fallback",
		"prompt": "Content could not be loaded - explore the line!",
		"target_value": 1.0,
		"tolerance": 0.5,
		"kind": "rational",
		"explain_correct": "1 is a real number.",
		"explain_wrong": "Try the middle of the line.",
		"citation": ""
	}]


func _build_fallback() -> void:
	_cfg = {}
	_marker_tasks = _fallback_tasks()
	_rebuild()


func _rebuild() -> void:
	for node in _spawned:
		if is_instance_valid(node):
			node.queue_free()
	_spawned.clear()
	_task_index = -1
	_tasks_done = 0

	var nld: Dictionary = _cfg.get("number_line", {}) if not _cfg.is_empty() else {}
	var mn := float(nld.get("min_value", -4.0)) if not nld.is_empty() else -4.0
	var mx := float(nld.get("max_value", 4.0)) if not nld.is_empty() else 4.0

	# --- Bar ---
	var bar := MeshInstance3D.new()
	var bar_mesh := BoxMesh.new()
	bar_mesh.size = Vector3(_line_x1 - _line_x0, 0.12, 0.3)
	bar.mesh = bar_mesh
	var bar_mat := StandardMaterial3D.new()
	bar_mat.albedo_color = COL_BAR
	bar.material_override = bar_mat
	add_child(bar)
	_spawned.append(bar)

	# --- Ticks + number labels -4..4 ---
	for n in range(-4, 5):
		var x := _value_to_x(float(n), mn, mx)
		var tick := MeshInstance3D.new()
		var tick_mesh := BoxMesh.new()
		tick_mesh.size = Vector3(0.08, 0.5, 0.12)
		tick.mesh = tick_mesh
		tick.position = Vector3(x, 0.2, 0)
		var tm := StandardMaterial3D.new()
		tm.albedo_color = COL_TICK
		tick.material_override = tm
		add_child(tick)
		_spawned.append(tick)

		var lbl := Label3D.new()
		lbl.text = str(n)
		lbl.font_size = 64
		lbl.pixel_size = 0.005
		lbl.position = Vector3(x, -0.55, 0)
		lbl.modulate = Color(0.92, 0.95, 1)
		lbl.outline_size = 12
		add_child(lbl)
		_spawned.append(lbl)

	# --- Marker (student moves this) ---
	_marker = Node3D.new()
	_marker.position = Vector3(_value_to_x(0.0, mn, mx), 0.7, 0)
	add_child(_marker)
	_spawned.append(_marker)

	var cone := MeshInstance3D.new()
	var cone_mesh := CylinderMesh.new()
	cone_mesh.top_radius = 0.0
	cone_mesh.bottom_radius = 0.28
	cone_mesh.height = 0.7
	cone.mesh = cone_mesh
	cone.rotation = Vector3(PI, 0, 0)  # point down at the line
	var cm := StandardMaterial3D.new()
	cm.albedo_color = COL_MARKER
	cm.emission_enabled = true
	cm.emission = COL_MARKER
	cm.emission_energy_multiplier = 0.6
	cone.material_override = cm
	_marker.add_child(cone)

	_marker_label = Label3D.new()
	_marker_label.font_size = 56
	_marker_label.pixel_size = 0.005
	_marker_label.position = Vector3(0, 0.85, 0)
	_marker_label.modulate = COL_MARKER
	_marker_label.outline_size = 10
	_marker.add_child(_marker_label)
	_marker_value = 0.0
	_update_marker_label()

	# --- Quiz orbs from data ---
	var orbs: Variant = _cfg.get("quiz_orbs", []) if not _cfg.is_empty() else []
	var orb_scene: PackedScene = load(ORB_SCENE)
	if orbs is Array:
		for od in orbs:
			if not (od is Dictionary):
				push_error("NumberLineActivity: invalid quiz orb skipped.")
				continue
			var orb_cfg: Dictionary = od
			var val: Variant = orb_cfg.get("value")
			if not (val is float or val is int):
				push_error("NumberLineActivity: orb '%s' has no numeric value; skipped."
					% String(orb_cfg.get("id", "?")))
				continue
			var orb := orb_scene.instantiate() as QuizOrb
			orb.value = float(val)
			orb.statement = String(orb_cfg.get("statement", ""))
			orb.is_true = bool(orb_cfg.get("is_true", false))
			orb.explain = String(orb_cfg.get("explain", ""))
			orb.value_to_x = Callable(self, "_value_to_x").bind(mn, mx)
			add_child(orb)
			orb.answered.connect(_on_orb_answered)
			_spawned.append(orb)

	_next_task()


func _value_to_x(value: float, mn: float = -4.0, mx: float = 4.0) -> float:
	var t := (value - mn) / (mx - mn)
	return lerpf(_line_x0, _line_x1, t)


func _update_marker_label() -> void:
	_marker_label.text = "%.2f" % _marker_value


# ------------------------------------------------------------- task flow

func _next_task() -> void:
	_task_index += 1
	if _task_index >= _marker_tasks.size():
		_status.text = "Number line mastered! Open the lesson for the quiz."
		activity_completed.emit()
		return
	var task: Dictionary = _marker_tasks[_task_index]
	_status.text = String(task.get("prompt", ""))
	task_changed.emit(String(task.get("prompt", "")))
	_update_marker_label()


func marker_left() -> void:
	_move_marker(-marker_step)


func marker_right() -> void:
	_move_marker(marker_step)


func _move_marker(delta_value: float) -> void:
	var nld: Dictionary = _cfg.get("number_line", {}) if not _cfg.is_empty() else {}
	var mn := float(nld.get("min_value", -4.0)) if not nld.is_empty() else -4.0
	var mx := float(nld.get("max_value", 4.0)) if not nld.is_empty() else 4.0
	_marker_value = clampf(_marker_value + delta_value, mn, mx)
	_marker.position.x = _value_to_x(_marker_value, mn, mx)
	_update_marker_label()


func submit_marker() -> void:
	if _task_index < 0 or _task_index >= _marker_tasks.size():
		return
	var task: Dictionary = _marker_tasks[_task_index]
	var target := float(task.get("target_value", 0.0))
	var tol := float(task.get("tolerance", 0.2))
	var ok := absf(_marker_value - target) <= tol
	var kind := String(task.get("kind", "rational"))

	# Leave a persistent dot at the attempted position.
	_spawn_result_dot(_marker_value, ok)

	var msg := String(task.get("explain_correct", "")) if ok \
		else String(task.get("explain_wrong", ""))
	if not msg.is_empty():
		_status.text = ("Correct! " if ok else "Not quite. ") + msg
		task_changed.emit(_status.text)
	if ok:
		_tasks_done += 1
		_spawn_confetti_at(target, kind)
		await get_tree().create_timer(2.2).timeout
		if is_instance_valid(self):
			_next_task()


func _spawn_result_dot(value: float, ok: bool) -> void:
	var nld: Dictionary = _cfg.get("number_line", {}) if not _cfg.is_empty() else {}
	var mn := float(nld.get("min_value", -4.0)) if not nld.is_empty() else -4.0
	var mx := float(nld.get("max_value", 4.0)) if not nld.is_empty() else 4.0
	var dot := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 0.16
	mesh.height = 0.32
	dot.mesh = mesh
	dot.position = Vector3(_value_to_x(value, mn, mx), 0.12, 0.55)
	var m := StandardMaterial3D.new()
	m.albedo_color = COL_ORB_OK if ok else COL_ORB_BAD
	dot.material_override = m
	add_child(dot)
	_spawned.append(dot)


func _spawn_confetti_at(value: float, kind: String) -> void:
	var col := COL_RATIONAL if kind == "rational" else COL_IRRATIONAL
	var ring := MeshInstance3D.new()
	var mesh := TorusMesh.new()
	mesh.inner_radius = 0.3
	mesh.outer_radius = 0.45
	ring.mesh = mesh
	ring.position = Vector3(_value_to_x(value), 0.9, 0)
	ring.scale = Vector3.ONE * 0.2
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.emission_enabled = true
	m.emission = col
	m.emission_energy_multiplier = 1.5
	ring.material_override = m
	add_child(ring)
	_spawned.append(ring)
	var tw := ring.create_tween()
	tw.tween_property(ring, "scale", Vector3.ONE, 0.5) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _on_orb_answered(_orb: QuizOrb) -> void:
	# Orb answers count as progress pings; the quiz itself lives in the lesson.
	pass


## True when every marker task has been completed (drives station mastery UI).
func is_completed() -> bool:
	return _tasks_done >= _marker_tasks.size() and _marker_tasks.size() > 0


## Cheap celebratory pulse on the whole activity when the lesson quiz passes.
func celebrate() -> void:
	_spawn_confetti_at(0.0, "irrational")
