extends SceneTree
## Runtime smoke test (offline, headless): drives the presentation lesson
## end-to-end for the verified topic math.u01.real-numbers — slides,
## checkpoint answer matching, scored practice, the three-question quiz,
## and the persisted understanding score. Run:
##   godot --headless --path . --script tools/smoke_presentation.gd
## Exit 0 = flow works; exit 1 = any assertion failed.
##
## NOTE: this script intentionally avoids compile-time references to
## LessonPresentation: in --script mode the dependency would compile before
## _initialize, when autoload singletons (GameSession) are not yet
## registered. All access is dynamic (get/set/call) instead.

const TOPIC_ID := "math.u01.real-numbers"
## LessonPresentation.Phase enum (dynamic mirror): SLIDES=0, PRACTICE=1,
## QUIZ=2, SCORE=3.
const PHASE_PRACTICE := 1
const PHASE_QUIZ := 2


func _initialize() -> void:
	var failures: Array[String] = []
	var packed: PackedScene = load("res://scenes/lesson_presentation.tscn")
	if packed == null:
		_fail(failures, "presentation scene failed to load")
		_finish(failures, null)
		return
	var pres: Control = packed.instantiate() as Control
	if pres == null:
		_fail(failures, "presentation instantiate returned null")
		_finish(failures, null)
		return
	root.add_child(pres)
	await process_frame
	pres.call("open_topic", TOPIC_ID)
	await process_frame

	# --- slides ---
	var slides: Array = pres.get("slides")
	if slides.size() != 5:
		_fail(failures, "expected 5 slides, got %d" % slides.size())
	if int(pres.get("slide_index")) != 0:
		_fail(failures, "first slide not shown (index=%s)" % str(pres.get("slide_index")))

	# --- checkpoint 1: accepted answer with noise + casing ---
	pres.call("_handle_checkpoint_answer", "  Rational AND Irrational numbers!  ")
	var done: Array = pres.get("_checkpoint_done")
	if done.is_empty() or not bool(done[0]):
		_fail(failures, "checkpoint 1 should accept 'Rational AND Irrational numbers'")

	# --- wrong answer stays safe (reviewed retry text, no crash) ---
	pres.call("_handle_checkpoint_answer", "bananas")
	await process_frame

	# --- drive to the end of the slides ---
	for i: int in 10:
		pres.call("_go_next")
		await process_frame
	if int(pres.get("_phase")) != PHASE_PRACTICE:
		_fail(failures, "expected PRACTICE phase after slides, got %s"
			% str(pres.get("_phase")))

	# --- practice: first submission reveals the reviewed solution ---
	pres.call("_handle_practice_input", "draw OA then AB")
	await process_frame
	if not bool(pres.get("_practice_awaiting_selfcheck")):
		_fail(failures, "practice should await self-check after first submission")
	# --- self-check 'yes' scores the item exactly once ---
	pres.call("_handle_practice_input", "yes")
	if int(pres.get("_practice_correct")) != 1:
		_fail(failures, "practice_correct expected 1, got %s"
			% str(pres.get("_practice_correct")))

	# --- quiz: answer all three with the correct indices ---
	if int(pres.get("_phase")) != PHASE_QUIZ:
		_fail(failures, "expected QUIZ phase, got %s" % str(pres.get("_phase")))
	var quiz_data: Array = pres.get("_quiz_data")
	if quiz_data.size() != 3:
		_fail(failures, "expected 3 quiz questions, got %d" % quiz_data.size())
	for qi: int in 3:
		var correct_idx := int((quiz_data[qi] as Dictionary).get("correct_index", -1))
		pres.call("_on_quiz_choice", correct_idx)
		await process_frame
	if int(pres.get("_quiz_correct")) != 3:
		_fail(failures, "quiz_correct expected 3, got %s" % str(pres.get("_quiz_correct")))

	# --- score: 100 quiz + 100 practice -> 100 ---
	var progress := LearningProgress.new()
	progress.load_progress()
	var entry := progress.get_topic(TOPIC_ID)
	if int(entry.get("latest_understanding", -1)) != 100:
		_fail(failures, "latest_understanding expected 100, got %s"
			% str(entry.get("latest_understanding", -1)))
	if int(entry.get("best_understanding", -1)) != 100:
		_fail(failures, "best_understanding expected 100, got %s"
			% str(entry.get("best_understanding", -1)))
	if int(entry.get("attempt_count", 0)) != 1:
		_fail(failures, "attempt_count expected 1, got %s"
			% str(entry.get("attempt_count", 0)))
	if int(entry.get("last_understanding_quiz_percent", -1)) != 100:
		_fail(failures, "quiz_percent component expected 100")
	if int(entry.get("last_understanding_practice_percent", -1)) != 100:
		_fail(failures, "practice_percent component expected 100")
	if not bool(entry.get("first_completion_rewarded", false)):
		_fail(failures, "first completion reward flag not set")

	# --- incomplete retry must not double-count attempts or rewards ---
	var xp_before := int(entry.get("xp", 0))
	var attempts_before := int(entry.get("attempt_count", 1))
	pres.set("_quiz_index", 0)
	pres.set("_quiz_correct", 0)
	var answered: Array = pres.get("_quiz_answered_first")
	answered.clear()
	pres.call("_on_quiz_choice", int((quiz_data[0] as Dictionary).get("correct_index", -1)))
	var progress2 := LearningProgress.new()
	progress2.load_progress()
	var entry2 := progress2.get_topic(TOPIC_ID)
	if int(entry2.get("attempt_count", 0)) != attempts_before:
		_fail(failures, "incomplete retry changed attempt_count")
	if int(entry2.get("xp", 0)) < xp_before:
		_fail(failures, "xp unexpectedly decreased")

	_finish(failures, pres)


func _fail(failures: Array[String], message: String) -> void:
	failures.append(message)
	push_error("SMOKE FAIL: " + message)


func _finish(failures: Array[String], pres: Control) -> void:
	if pres != null and is_instance_valid(pres):
		pres.queue_free()
	if failures.is_empty():
		print("SMOKE OK: presentation flow, scoring, and persistence verified")
		quit(0)
	else:
		print("SMOKE FAILED: %d assertions" % failures.size())
		for f in failures:
			print("  - ", f)
		quit(1)
