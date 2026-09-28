extends Area3D
class_name LearningStation
## A configurable topic station in AngelTown. Adding a future topic station is
## configuration only: set `topic_id`, `display_title`, `zone` and `available`
## in the inspector (or on a scene instance) — no per-topic script needed.
##
## The station only reports interactions; opening content is the world
## controller's job (it checks GameSession.has_topic_content). Stations with
## `available = false` are honestly shown as "Coming soon" and never open
## fabricated content.

signal player_entered(station: LearningStation)
signal player_exited(station: LearningStation)

@export var topic_id := "math.u01.real-numbers"
@export var display_title := "1.1 Introduction to Real Numbers"
@export var zone := "Math Meadows"
@export var available := true
## Optional override of the content file (defaults to GameSession lookup).
@export var content_override_path := ""

var _player_in_range := false

@onready var _label: Label3D = $Sign/TitleLabel
@onready var _ring: MeshInstance3D = $Ring


func _ready() -> void:
	monitoring = true
	_apply_identity()
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	set_ring_active(false)


func _apply_identity() -> void:
	_label.text = display_title
	var subtitle := "Tap Interact"
	if not available:
		subtitle = "Coming soon"
	elif zone != "":
		subtitle = zone + " - Tap Interact"
	$Sign/SubtitleLabel.text = subtitle
	# Locked stations get a muted ring; active ones keep the amber glow.
	var ring_mat := _ring.get_surface_override_material(0) as StandardMaterial3D
	if ring_mat != null:
		ring_mat.emission_enabled = available
		ring_mat.emission_energy_multiplier = 1.2 if available else 0.0


func set_ring_active(active: bool) -> void:
	var ring_mat := _ring.get_surface_override_material(0) as StandardMaterial3D
	if ring_mat != null:
		ring_mat.emission_energy_multiplier = 2.2 if active else (1.2 if available else 0.0)


func is_player_in_range() -> bool:
	return _player_in_range


func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		_player_in_range = true
		player_entered.emit(self)


func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		_player_in_range = false
		player_exited.emit(self)
