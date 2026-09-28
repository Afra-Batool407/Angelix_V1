extends RefCounted
class_name TownSettings
## Versioned local settings for the AngelTown world (separate from learning
## progress): Performance Mode and the player's last safe world position.
##
## File: user://angel_town_settings.json
## Missing/malformed/older files fall back to defaults without errors.
## Positions are validated on load AND on restore (bounds + ground height)
## so a bad save can never place the student inside terrain or outside the
## playable area.

const SAVE_PATH := "user://angel_town_settings.json"
const SCHEMA_VERSION := 2

## Playable bounds (matches terrain size and scatter range, with margin).
const BOUNDS_X := Vector2(-30.0, 30.0)
const BOUNDS_Z := Vector2(-32.0, 28.0)
const MAX_Y := 12.0

var performance_mode := false
var has_player_position := false
var player_position := Vector3.ZERO


func load_settings() -> bool:
	performance_mode = false
	has_player_position = false
	player_position = Vector3.ZERO
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return false
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if not (parsed is Dictionary):
		return false
	var root: Dictionary = parsed
	var ver := int(root.get("schema_version", 0))
	if ver > SCHEMA_VERSION:
		return false  # newer than we understand: start clean, never corrupt
	performance_mode = bool(root.get("performance_mode", false))
	if root.has("player_position"):
		var pos: Variant = root.get("player_position")
		if pos is Dictionary:
			var pd: Dictionary = pos
			var v := Vector3(
				float(pd.get("x", 0.0)), float(pd.get("y", 0.0)), float(pd.get("z", 0.0)))
			if is_valid_position(v):
				player_position = v
				has_player_position = true
	return true


## Static validity: finite and inside the playable bounds.
static func is_valid_position(v: Vector3) -> bool:
	if is_nan(v.x) or is_nan(v.y) or is_nan(v.z):
		return false
	if is_inf(v.x) or is_inf(v.y) or is_inf(v.z):
		return false
	if v.x < BOUNDS_X.x or v.x > BOUNDS_X.y:
		return false
	if v.z < BOUNDS_Z.x or v.z > BOUNDS_Z.y:
		return false
	if v.y < 0.0 or v.y > MAX_Y:
		return false
	return true


func save_settings() -> bool:
	var root := {
		"schema_version": SCHEMA_VERSION,
		"performance_mode": performance_mode,
		"player_position": {
			"x": player_position.x, "y": player_position.y, "z": player_position.z,
		},
	}
	var tmp_path := SAVE_PATH + ".tmp"
	var f := FileAccess.open(tmp_path, FileAccess.WRITE)
	if f == null:
		push_error("TownSettings: cannot write %s" % tmp_path)
		return false
	f.store_string(JSON.stringify(root, "  "))
	f.close()
	var da := DirAccess.open("user://")
	if da != null and da.file_exists(SAVE_PATH):
		da.remove(SAVE_PATH)
	var err := da.rename(tmp_path.get_file(), SAVE_PATH.get_file())
	if err != OK:
		push_error("TownSettings: rename failed (%s)" % err)
		return false
	return true


func clear_player_position() -> void:
	has_player_position = false
	player_position = Vector3.ZERO
