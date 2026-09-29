extends RefCounted
class_name VoiceManager
## Offline TTS wrapper using ONLY the Godot 4.7 DisplayServer API verified
## against the real 4.7.2 binary (ClassDB dump, tools/dump_tts_api.gd):
##   tts_speak(text: String, voice: String, volume: float, pitch: float,
##             rate: float, utterance_id: int, interrupt: bool)
##   tts_stop(), tts_is_speaking() -> bool,
##   tts_get_voices() -> Array, FEATURE_TEXT_TO_SPEECH feature flag.
##
## Android system TTS is exposed through the same DisplayServer interface;
## actual voice availability/quality is device-dependent and must be
## confirmed on hardware. If the feature is missing or no voices exist,
## this manager reports unavailable and the presentation keeps all
## narration visible as text. Never blocks, never touches the network.

## Gentle-presenter defaults within the documented 0.5..2.0 pitch/rate range.
const DEFAULT_VOLUME := 0.0
const DEFAULT_PITCH := 1.05
const DEFAULT_RATE := 0.95
const UTTERANCE_ID := 1

var available := false
var voice_id := ""
var pitch := DEFAULT_PITCH
var rate := DEFAULT_RATE


func _init() -> void:
	if not DisplayServer.has_feature(DisplayServer.FEATURE_TEXT_TO_SPEECH):
		return
	var voices: Array = DisplayServer.tts_get_voices()
	if voices.is_empty():
		return
	# Prefer an English system voice; fall back to the first listed voice.
	for v: Variant in voices:
		if v is Dictionary:
			var vid := String((v as Dictionary).get("id", ""))
			var lang := String((v as Dictionary).get("language", ""))
			if vid != "" and lang.to_lower().begins_with("en"):
				voice_id = vid
				break
	if voice_id.is_empty():
		var first: Variant = voices[0]
		if first is Dictionary:
			voice_id = String((first as Dictionary).get("id", ""))
	available = not voice_id.is_empty()


## Speaks reviewed narration. No-ops safely when unavailable; the caller
## always shows the same text on screen, so audio is never required.
func speak(text: String) -> void:
	if not available or text.strip_edges().is_empty():
		return
	DisplayServer.tts_speak(text, voice_id, DEFAULT_VOLUME, pitch, rate,
		UTTERANCE_ID, false)


func stop() -> void:
	if available:
		DisplayServer.tts_stop()


func is_speaking() -> bool:
	if not available:
		return false
	return DisplayServer.tts_is_speaking()
