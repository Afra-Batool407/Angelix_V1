extends RefCounted
class_name LearningProgress
## Versioned offline progress store, saved as JSON under user://.
##
## File: user://learning_progress.json
## {
##   "schema_version": 1,
##   "topics": {
##     "<topic_id>": {
##       "topic_id": "...",
##       "attempt_count": int,
##       "latest_score": int,      # 0..3 correct answers of the latest quiz attempt
##       "best_score": int,        # 0..3
##       "mastered": bool,         # true when best_score == 3
##       "last_attempt_ms": int    # Unix ms of last quiz attempt (0 = never)
##     }
##   }
## }
##
## Safety contract: a missing, malformed, or older-schema file never blocks
## starting a lesson — the store falls back to a fresh empty state. Saves are
## atomic (tmp file + rename). Keyed by stable topic ID, never display title.
## No personal information is stored.

const SAVE_PATH := "user://learning_progress.json"
const SCHEMA_VERSION := 1

var _topics := {}


## Loads the save file, tolerating missing/malformed/older data.
func load_progress() -> bool:
	_topics = {}
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return false
	var raw := f.get_as_text()
	f.close()
	var parsed: Variant = JSON.parse_string(raw)
	if not (parsed is Dictionary):
		return false
	var root: Dictionary = parsed
	var ver := int(root.get("schema_version", 0))
	if ver > SCHEMA_VERSION:
		# Newer than we understand: start clean rather than corrupt it.
		return false
	var topics: Variant = root.get("topics", {})
	if not (topics is Dictionary):
		return false
	for key in topics:
		var entry: Variant = topics[key]
		if entry is Dictionary:
			_topics[String(key)] = _sanitize_entry(entry, String(key))
	return true


func _sanitize_entry(entry: Dictionary, topic_id: String) -> Dictionary:
	return {
		"topic_id": String(entry.get("topic_id", topic_id)),
		"attempt_count": maxi(0, int(entry.get("attempt_count", 0))),
		"latest_score": clampi(int(entry.get("latest_score", 0)), 0, 3),
		"best_score": clampi(int(entry.get("best_score", 0)), 0, 3),
		"mastered": bool(entry.get("mastered", false)),
		"last_attempt_ms": maxi(0, int(entry.get("last_attempt_ms", 0))),
		# v1 -> v1.1 optional field; missing = false (safe migration).
		"activity_done": bool(entry.get("activity_done", false)),
	}


func save_progress() -> bool:
	var root := {"schema_version": SCHEMA_VERSION, "topics": _topics}
	var tmp_path := SAVE_PATH + ".tmp"
	var f := FileAccess.open(tmp_path, FileAccess.WRITE)
	if f == null:
		push_error("LearningProgress: cannot write %s" % tmp_path)
		return false
	f.store_string(JSON.stringify(root, "  "))
	f.close()
	# Atomic replace where the OS supports it; DirAccess handles this on Android.
	var da := DirAccess.open("user://")
	if da != null and da.file_exists(SAVE_PATH):
		da.remove(SAVE_PATH)
	var err := da.rename(tmp_path.get_file(), SAVE_PATH.get_file())
	if err != OK:
		push_error("LearningProgress: rename failed (%s)" % err)
		return false
	return true


func get_topic(topic_id: String) -> Dictionary:
	if _topics.has(topic_id):
		return _topics[topic_id]
	return {
		"topic_id": topic_id,
		"attempt_count": 0,
		"latest_score": 0,
		"best_score": 0,
		"mastered": false,
		"last_attempt_ms": 0,
	}


## Marks the in-world activity complete for a topic (idempotent).
func set_activity_done(topic_id: String, done: bool) -> void:
	var entry := get_topic(topic_id)
	entry["activity_done"] = done
	_topics[topic_id] = entry
	save_progress()


## Records one finished quiz attempt (score = number of correct answers 0..3).
func record_attempt(topic_id: String, score: int) -> Dictionary:
	var entry := get_topic(topic_id)
	var s := clampi(score, 0, 3)
	entry["attempt_count"] = int(entry["attempt_count"]) + 1
	entry["latest_score"] = s
	entry["best_score"] = maxi(int(entry["best_score"]), s)
	entry["mastered"] = int(entry["best_score"]) >= 3
	entry["last_attempt_ms"] = int(Time.get_unix_time_from_system() * 1000.0)
	_topics[topic_id] = entry
	save_progress()
	return entry
