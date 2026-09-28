extends CharacterBody3D
## Angel — procedural glide controller.
## The Angel floats over the terrain: idle hover-bob when still, gliding
## motion (with banking and forward tilt) when moving. All animation is
## procedural (code/tweens), so no rigged model is required. When a real
## Angel mesh is added later, swap it into the "Visual" node — the
## movement code stays identical.
##
## Input: Android touch joystick (TouchJoystick in the scene) and/or
## keyboard (WASD / arrows) for desktop testing. Camera-relative movement.

signal moved(is_moving: bool)

const SPEED := 7.0
const ACCEL := 12.0
const DECEL := 10.0
const TURN_SPEED := 10.0
const GRAVITY := 18.0
const HOVER_HEIGHT := 2.2
const BOB_AMP := 0.14
const BOB_TIME := 2.2
const BANK_ANGLE := 0.35
const TILT_ANGLE := 0.12
const WING_FLAP_TIME := 1.1

var _input_dir := Vector2.ZERO
var _bob_phase := 0.0
var _wing_phase := 0.0
var _visual_yaw := 0.0
var _bob_offset := 0.0

## Mood -> procedural state. The imported Angel model has NO AnimationPlayer
## clips (verified: angel.tscn is pure geometry + this script), so moods map
## onto verified procedural parameters with "neutral" as the safe fallback.
var _mood_energy := 1.0   ## glow energy multiplier
var _mood_flap := 1.0     ## wing flap speed multiplier


func set_mood(mood: String) -> void:
	match mood:
		"happy":
			_mood_energy = 1.3
			_mood_flap = 1.2
		"excited":
			_mood_energy = 1.8
			_mood_flap = 1.8
		"thinking":
			_mood_energy = 0.9
			_mood_flap = 0.7
		_:
			_mood_energy = 1.0   # neutral and any unknown mood: safe fallback
			_mood_flap = 1.0

@onready var _visual: Node3D = $Visual
@onready var _wings: Node3D = $Visual/Wings
@onready var _wing_l: Node3D = $Visual/Wings/WingL
@onready var _wing_r: Node3D = $Visual/Wings/WingR
@onready var _halo: Node3D = $Visual/Halo
@onready var _body: MeshInstance3D = $Visual/Body
@onready var _glow: OmniLight3D = $Visual/Glow


func _ready() -> void:
	# Spawn a little above the ground and let gravity settle the hover height.
	global_position.y += 4.0


func _physics_process(delta: float) -> void:
	_input_dir = _gather_input()

	# --- Horizontal movement (camera-relative) ---
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
	var dir := (right * _input_dir.x + forward * _input_dir.y)
	var moving := dir.length_squared() > 0.01

	var target_h := dir * SPEED
	var h := Vector3(velocity.x, 0.0, velocity.z)
	h = h.move_toward(target_h, (ACCEL if moving else DECEL) * delta)

	# --- Vertical: settle to hover height above the ground, plus bob ---
	var ground_y := _terrain_height_at(global_position.x, global_position.z)
	var hover_y := ground_y + HOVER_HEIGHT
	_bob_phase += delta * TAU / BOB_TIME
	_bob_offset = sin(_bob_phase) * BOB_AMP
	var vy := (hover_y + _bob_offset - global_position.y) * 6.0
	if not is_on_floor():
		vy -= GRAVITY * delta * 0.5  # mild extra pull while settling

	velocity = Vector3(h.x, vy, h.z)
	move_and_slide()

	# --- Facing: turn smoothly toward movement direction ---
	if moving:
		_visual_yaw = lerp_angle(_visual_yaw, atan2(-h.x, -h.z), TURN_SPEED * delta)
	_visual.rotation.y = _visual_yaw

	# --- Procedural pose: bank into turns, tilt forward with speed ---
	var speed_frac := h.length() / SPEED
	var local_dir := Vector3.ZERO
	if moving:
		local_dir = _visual.global_transform.basis.inverse() * h.normalized()
	_visual.rotation.z = lerp(_visual.rotation.z, -local_dir.x * BANK_ANGLE, 8.0 * delta)
	_visual.rotation.x = lerp(_visual.rotation.x, speed_frac * TILT_ANGLE, 8.0 * delta)

	# --- Wing flap: slow majestic beat, faster while gliding ---
	_wing_phase += delta * _mood_flap * TAU / (WING_FLAP_TIME / (1.0 + speed_frac * 0.8))
	var flap := sin(_wing_phase)
	_wing_l.rotation.z = deg_to_rad(18.0) + flap * deg_to_rad(14.0)
	_wing_r.rotation.z = -deg_to_rad(18.0) - flap * deg_to_rad(14.0)
	_wings.rotation.x = -flap * 0.06

	# --- Halo spin and pulse; body glow breathes ---
	_halo.rotation.y += delta * 1.6
	_halo.scale = Vector3.ONE * (1.0 + 0.04 * sin(_bob_phase * 2.0))
	_glow.light_energy = (0.9 + 0.25 * sin(_bob_phase * 2.0)) * _mood_energy
	_body.scale.y = 1.0 + 0.02 * sin(_bob_phase * 2.0 + PI / 3.0)

	moved.emit(moving)


func _gather_input() -> Vector2:
	var v := Vector2.ZERO
	# Keyboard for desktop testing.
	v.x = Input.get_axis("move_left", "move_right")
	v.y = Input.get_axis("move_forward", "move_back")
	# Touch joystick (Android).
	var joys := get_tree().get_nodes_in_group("joystick")
	if joys.size() > 0 and joys[0].is_active():
		v = joys[0].get_direction()
	if v.length() > 1.0:
		v = v.normalized()
	return v


func _terrain_height_at(x: float, z: float) -> float:
	# Sample the world downward at this position (terrain is the only static
	# collider). Keeps hover height cheap without raycast allocation churn.
	var space := get_world_3d().direct_space_state
	var from := Vector3(x, global_position.y + 6.0, z)
	var to := Vector3(x, global_position.y - 30.0, z)
	var q := PhysicsRayQueryParameters3D.create(from, to, 1)  # layer 1 = terrain
	var hit := space.intersect_ray(q)
	if hit:
		return float(hit["position"].y)
	return 0.0
