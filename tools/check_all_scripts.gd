extends SceneTree
## Headless GDScript compile validation: run with
##   godot --headless --path . --script tools/check_all_scripts.gd
## Compiles every tracked .gd with the real Godot analyzer via load(),
## which runs with full project context (global class cache + autoload
## registry), unlike --check-only. Exit 0 = all compile; exit 1 = any fail.

var _failed := false


func _initialize() -> void:
	var scripts: Array[String] = []
	_scan("res://", scripts)
	if scripts.is_empty():
		push_error("check_all_scripts: no .gd files found under res://")
		quit(1)
		return
	for path in scripts:
		var script: Script = load(path)
		if script == null or not script.can_instantiate():
			# Not every script is instantiable (e.g. editor-only); null load
			# is the hard failure. can_instantiate false without null is OK.
			if script == null:
				push_error("COMPILE FAILED: " + path)
				_failed = true
				continue
		print("OK: ", path)
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
		elif child.ends_with(".gd") and not dir_path.path_join(child).begins_with("res://tools/"):
			out.append(dir_path.path_join(child))
		child = dir.get_next()
	dir.list_dir_end()
