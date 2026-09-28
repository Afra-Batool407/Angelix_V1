extends Area3D
class_name QuizOrb
## A walk-to / tap true-false marker on the in-world number line.
## Target, statement, answer, and feedback are all data-driven; orbs never
## contain lesson content themselves.

signal answered(orb: QuizOrb)

@export var value := 0.0
@export var statement := ""
@export var is_true := false
@export var explain := ""

## Set by the activity: maps this orb's value to a world X position.
var value_to_x := Callable()

var _answered := false

@onready var _mesh: MeshInstance3D = $Mesh
@onready var _label: Label3D = $Label


func _ready() -> void:
	monitoring = true
	if value_to_x.is_valid():
		position.x = value_to_x.call(value)
	body_entered.connect(_on_body_entered)


func set_floating_text(text: String) -> void:
	_label.text = text


func _on_body_entered(body: Node3D) -> void:
	if _answered or not body.is_in_group("player"):
		return
	_answered = true
	_show_result()


func _show_result() -> void:
	var col := Color(0.4, 0.9, 0.6) if is_true else Color(0.95, 0.45, 0.45)
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.emission_enabled = true
	m.emission = col
	m.emission_energy_multiplier = 1.4
	_mesh.material_override = m
	_label.text = explain
	# Node3D has no modulate: pop-shrink the orb and fade the label instead.
	var tw := create_tween()
	tw.tween_interval(4.0)
	tw.set_parallel(true)
	tw.tween_property(self, "scale", Vector3.ONE * 0.05, 0.6)
	tw.tween_property(_label, "modulate:a", 0.0, 0.6)
	tw.chain().tween_callback(queue_free)
	answered.emit(self)
