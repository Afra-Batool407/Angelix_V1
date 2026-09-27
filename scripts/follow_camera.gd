extends Node3D
## Smooth follow rig: keeps this node lerping toward the target (Angel),
## so the SpringArm3D + Camera3D child orbit and collide correctly.

@export var target_path: NodePath
@export var follow_speed := 6.0
@export var height_offset := 1.2

var _target: Node3D
var _has_target := false


func _ready() -> void:
	_target = get_node_or_null(target_path) as Node3D
	_has_target = _target != null
	if _has_target:
		global_position = _target.global_position


func _physics_process(delta: float) -> void:
	if not _has_target or not is_instance_valid(_target):
		return
	var goal := _target.global_position + Vector3(0, height_offset, 0)
	var t := 1.0 - exp(-follow_speed * delta)
	global_position = global_position.lerp(goal, t)
