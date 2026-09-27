extends Control
## On-screen virtual joystick for Android (and mouse-drag on desktop).
## Place as a child of a CanvasLayer in the 3D world scene, anchored
## bottom-left. The player controller queries is_active()/get_direction().

@export var radius := 110.0
@export var knob_radius := 44.0
@export var dead_zone := 0.12

var _touch_index := -1
var _center := Vector2.ZERO
var _dir := Vector2.ZERO
var _pressed := false

@onready var _base: Control = $Base
@onready var _knob: Control = $Base/Knob


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_base.pivot_offset = _base.size / 2.0
	_base.modulate.a = 0.55
	_base.position = Vector2(-radius, -radius)
	_base.size = Vector2(radius * 2.0, radius * 2.0)
	_center = Vector2.ZERO
	_knob.position = _center - Vector2(knob_radius, knob_radius)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and _touch_index == -1:
			_touch_index = event.index
			_begin(Vector2(event.position))
		elif not event.pressed and event.index == _touch_index:
			_end()
	elif event is InputEventScreenDrag and event.index == _touch_index:
		_update_dir(Vector2(event.position))
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and _touch_index == -1:
			_touch_index = 0
			_begin(Vector2(event.position))
		elif not event.pressed and _touch_index == 0:
			_end()
	elif event is InputEventMouseMotion and _touch_index == 0 and _pressed:
		_update_dir(Vector2(event.position))


func _begin(local_pos: Vector2) -> void:
	_pressed = true
	_center = local_pos
	_base.modulate.a = 0.85
	_base.position = _center - Vector2(radius, radius)
	_knob.position = _center - Vector2(knob_radius, knob_radius)


func _update_dir(local_pos: Vector2) -> void:
	var v := local_pos - _center
	if v.length() > radius:
		v = v.normalized() * radius
	_knob.position = _center + v - Vector2(knob_radius, knob_radius)
	var n := v / radius
	_dir = Vector2.ZERO if n.length() < dead_zone else n


func _end() -> void:
	_touch_index = -1
	_pressed = false
	_dir = Vector2.ZERO
	_base.modulate.a = 0.55
	_base.position = Vector2(-radius, -radius)
	_knob.position = _center - Vector2(knob_radius, knob_radius)


func is_active() -> bool:
	return _pressed and _dir != Vector2.ZERO


func get_direction() -> Vector2:
	return _dir
