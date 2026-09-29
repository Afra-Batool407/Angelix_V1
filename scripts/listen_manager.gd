extends RefCounted
class_name ListenManager
## Optional listening input for the presentation lesson.
##
## Verified against the current project (inspected before building): there is
## NO Android speech-recognition plugin or GDExtension bridge in this project
## (no addons/ directory, no engine plugins in project.godot). Per the task
## rules, no new plugin may be added or assumed, so speech recognition ships
## DISABLED and typed input is always available.
##
## If a verified plugin is added later, wire it here: request the Android
## microphone permission only after an explicit Listen tap, keep recognition
## on-device, and route the final transcript into the same submit path as
## typed text.

var available := false


func _init() -> void:
	# No verified on-device STT bridge exists in this project (checked:
	# addons/, project.godot plugins section). Text-only input for now.
	available = false


## Human-readable status for the Listen button tooltip.
func status_text() -> String:
	if available:
		return "Voice input ready. Tap to listen."
	return "Voice input needs a supported speech plugin - please type your answer."
