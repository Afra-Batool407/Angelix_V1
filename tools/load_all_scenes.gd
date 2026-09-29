extends SceneTree
## Headless scene-load validation: run with
##   godot --headless --path . --script tools/load_all_scenes.gd
## Loads and instantiates every .tscn in the project with the real Godot
## parser (the check no offline Python regex validation can replace).
## Exit 0 = every scene parsed and instantiated; exit 1 = any failure.

var _failed := false


func _initialize() -> void:
	var scenes: Array[String] = []
	_scan("res://", scenes)
	if scenes.is_empty():
		push_error("load_all_scenes: no .tscn files found under res://")
		quit(1)
		return
	for path in scenes:
		var packed: PackedScene = load(path)
		if packed == null:
			push_error("LOAD FAILED: " + path)
			_failed = true
			continue
		var node := packed.instantiate()
		if node == null:
			push_error("INSTANTIATE FAILED: " + path)
			_failed = true
			continue
		print("OK: ", path)
		node.free()
	quit(1 if _failed else 0)


func _scan(dir_path: String, out: Array[String]) -> void:
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return
	dir.list_dir_begin()
	var child := dir.get_next()
	while child != "":
		if dir.current_is_dir() and not child.begins_with("."):
			_scan(dir_path.path_join(child), out)
		elif child.ends_with(".tscn"):
			out.append(dir_path.path_join(child))
		child = dir.get_next()
	dir.list_dir_end()
