extends CharacterBody3D
class_name PlayerController
## Simple student player for AngelTown (the smallest compatible version —
## no player controller existed in the project; Angel was the player).
##
## Walks on the procedural terrain (collision layer 1), reads the existing
## TouchJoystick (group "joystick") and/or keyboard actions for desktop
## testing. `locked` freezes movement while the lesson overlay is open
## without pausing lesson UI input.

const SPEED := 5.0
const ACCEL := 11.0
const DECEL := 12.0
const GRAVITY := 20.0

## When true (lesson overlay open), all movement input is ignored.
var locked := false

var _input_dir := Vector2.ZERO

@onready var _visual: Node3D = $Visual


func _physics_process(delta: float) -> void:
	if not locked:
		_input_dir = _gather_input()
	else:
		_input_dir = Vector2.ZERO

	# Camera-relative movement, same convention as the Angel controller.
	var cam := get_viewport().get_camera_3d()
	var forward := Vector3.FORWARD
	var right := Vector3.RIGHT
	if cam:
		var xf := cam.global_transform
		forward = -xf.basis.z
		forward.y = 0.0
		forward = forward.normalized()
		right = xf.basis.x
		right.y = 0.0
		right = right.normalized()
	var dir := right * _input_dir.x + forward * _input_dir.y
	var moving := dir.length_squared() > 0.01

	var target_h := dir * SPEED
	var h := Vector3(velocity.x, 0.0, velocity.z)
	h = h.move_toward(target_h, (ACCEL if moving else DECEL) * delta)

	# Gravity: settle onto the terrain, walk down slopes naturally.
	var vy := velocity.y
	if not is_on_floor():
		vy -= GRAVITY * delta
	elif vy < 0.0:
		vy = 0.0

	velocity = Vector3(h.x, vy, h.z)
	move_and_slide()

	# Face movement direction and add a tiny lean for life.
	if moving:
		var yaw := atan2(-h.x, -h.z)
		_visual.rotation.y = lerp_angle(_visual.rotation.y, yaw, 10.0 * delta)


func _gather_input() -> Vector2:
	var v := Vector2.ZERO
	v.x = Input.get_axis("move_left", "move_right")
	v.y = Input.get_axis("move_forward", "move_back")
	var joys := get_tree().get_nodes_in_group("joystick")
	if joys.size() > 0 and joys[0].is_active():
		v = joys[0].get_direction()
	if v.length() > 1.0:
		v = v.normalized()
	return v
