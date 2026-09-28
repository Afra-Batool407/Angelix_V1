extends Node
## GameSession (autoload): carries the selected stable topic ID from the menu
## into the persistent 3D world, and centralizes topic-content lookups.
##
## Topic IDs are the single shared key across menu selection, stations,
## lesson JSON, quizzes, and saved progress. Never store display titles here.

const CONTENT_DIR := "res://content/topics"

## Topic ID of the last card pressed in the menu ("" when entering the world
## without a selection, e.g. direct scene run).
var selected_topic_id := ""


## Stable content path for a topic ID (file may not exist).
func content_path_for(topic_id: String) -> String:
	return "%s/%s.json" % [CONTENT_DIR, topic_id]


## True only when a validated topic JSON actually exists on disk.
## Locked/"Coming soon" topics have no file and must never open fabricated
## content.
func has_topic_content(topic_id: String) -> bool:
	if topic_id.is_empty():
		return false
	return FileAccess.file_exists(content_path_for(topic_id))


## Loads and parses a topic JSON ({} when missing/malformed). Used by the
## world to read optional sections like `world_activity` without duplicating
## file handling.
func load_topic_data(topic_id: String) -> Dictionary:
	var path := content_path_for(topic_id)
	if not FileAccess.file_exists(path):
		return {}
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	return parsed if parsed is Dictionary else {}


## A station covers a topic family: an exact ID match, or a sub-topic of it
## (e.g. station "math.u01.real-numbers" is a spawn target for the menu's
## "math.u01.real-numbers.rational-irrational-combination" card).
func matches_station(selected_id: String, station_topic_id: String) -> bool:
	if selected_id.is_empty() or station_topic_id.is_empty():
		return false
	return selected_id == station_topic_id \
		or selected_id.begins_with(station_topic_id + ".")
