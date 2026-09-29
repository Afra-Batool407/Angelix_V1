extends RefCounted
class_name AngelPresenter
## Presentation-side Angel presenter. The imported Angel model has NO
## AnimationPlayer clips and is unrigged (verified: scenes/angel.tscn is pure
## geometry; scripts/angel.gd is fully procedural), so this presenter animates
## ONLY a presentation-local Control pivot with gentle bob/tilt transforms.
## It never touches the 3D follow root in the world and never claims limb
## animation.

var _pivot: Control
var _bob_tween: Tween
var _tilt_tween: Tween


func attach(pivot: Control) -> void:
	_pivot = pivot
	if _pivot == null:
		return
	_pivot.pivot_offset = _pivot.size * 0.5
	_start_bob()


func _start_bob() -> void:
	if _pivot == null:
		return
	_stop_tweens()
	_bob_tween = _pivot.create_tween().set_loops()
	_bob_tween.tween_property(_pivot, "position:y",
		_pivot.position.y - 4.0, 1.4).set_trans(Tween.TRANS_SINE) \
		.set_ease(Tween.EASE_IN_OUT)
	_bob_tween.tween_property(_pivot, "position:y",
		_pivot.position.y, 1.4).set_trans(Tween.TRANS_SINE) \
		.set_ease(Tween.EASE_IN_OUT)


## Gentle thinking tilt (mood: thinking/neutral).
func think() -> void:
	if _pivot == null:
		return
	_stop_tweens()
	_tilt_tween = _pivot.create_tween().set_loops()
	_tilt_tween.tween_property(_pivot, "rotation",
		deg_to_rad(2.5), 1.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_tilt_tween.tween_property(_pivot, "rotation",
		deg_to_rad(-2.5), 1.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


## Happy bounce on correct answers or encouragement (mood: happy/excited).
func celebrate() -> void:
	if _pivot == null:
		return
	_stop_tweens()
	var tw := _pivot.create_tween()
	tw.tween_property(_pivot, "scale", Vector2(1.06, 1.06), 0.18) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_property(_pivot, "scale", Vector2.ONE, 0.22) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_callback(_start_bob)


func set_mood(mood: String) -> void:
	match mood:
		"happy", "excited":
			celebrate()
		"thinking":
			think()
		_:
			_start_bob()


func stop() -> void:
	_stop_tweens()


func _stop_tweens() -> void:
	if _bob_tween != null and _bob_tween.is_valid():
		_bob_tween.kill()
		_bob_tween = null
	if _tilt_tween != null and _tilt_tween.is_valid():
		_tilt_tween.kill()
		_tilt_tween = null
