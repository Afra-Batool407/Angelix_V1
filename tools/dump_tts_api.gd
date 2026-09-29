extends SceneTree
## One-off API verification (not part of CI): dumps the real Godot 4.7
## DisplayServer TTS method signatures from ClassDB so VoiceManager calls
## the exact verified API. Run:
##   godot --headless --path . --script tools/dump_tts_api.gd

func _initialize() -> void:
	print("FEATURE_TEXT_TO_SPEECH supported: ",
		DisplayServer.has_feature(DisplayServer.FEATURE_TEXT_TO_SPEECH))
	for m: Dictionary in ClassDB.class_get_method_list("DisplayServer"):
		var name := String(m.get("name", ""))
		if name.begins_with("tts_"):
			var args := []
			for arg: Dictionary in m.get("args", []):
				args.append(String(arg.get("name", "")) + ":" + str(arg.get("type", -1)))
			print("DisplayServer.", name, " -> ", m.get("return", {}).get("type", "void"),
				" args=", args, " defaults=", m.get("default_arguments", []))
	quit(0)
