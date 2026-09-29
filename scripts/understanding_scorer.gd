extends RefCounted
class_name UnderstandingScorer
## Understanding score: round(0.75 * quiz_percent + 0.25 * practice_percent).
##
## The caller supplies FIRST submitted answers only (retries never count as
## new items). At least one scored practice item is required; anything else
## is a validation error, never a silently changed formula.

const QUIZ_WEIGHT := 0.75
const PRACTICE_WEIGHT := 0.25
const QUIZ_TOTAL := 3


## Returns {ok, error, quiz_percent, practice_percent, understanding_percent}.
## On validation failure ok=false and the percents are 0 — the caller must
## surface the error instead of saving a made-up score.
static func compute(quiz_correct: int, practice_correct: int,
		practice_total: int) -> Dictionary:
	if practice_total < 1:
		return _error("no scored practice item was recorded")
	if quiz_correct < 0 or quiz_correct > QUIZ_TOTAL:
		return _error("quiz_correct out of range 0..%d" % QUIZ_TOTAL)
	if practice_correct < 0 or practice_correct > practice_total:
		return _error("practice_correct out of range 0..%d" % practice_total)
	var quiz_percent := int(round(100.0 * float(quiz_correct) / float(QUIZ_TOTAL)))
	var practice_percent := int(round(100.0 * float(practice_correct) / float(practice_total)))
	var understanding := int(round(
		QUIZ_WEIGHT * float(quiz_percent) + PRACTICE_WEIGHT * float(practice_percent)))
	return {
		"ok": true,
		"error": "",
		"quiz_percent": quiz_percent,
		"practice_percent": practice_percent,
		"understanding_percent": clampi(understanding, 0, 100),
	}


static func _error(message: String) -> Dictionary:
	push_error("UnderstandingScorer: " + message)
	return {
		"ok": false,
		"error": message,
		"quiz_percent": 0,
		"practice_percent": 0,
		"understanding_percent": 0,
	}


## Supportive next-step message for a demonstrated-understanding estimate.
static func next_step(understanding: int) -> String:
	if understanding >= 80:
		return "Shabash! Strong understanding this attempt — replay the quiz anytime to keep it fresh, or explore the world's next station."
	if understanding >= 50:
		return "Good work! One more pass through the slides (Angel can explain again) should lift your quiz score."
	return "Solid start! Replay the slides, ask Angel for a hint, and try the quiz again — har koshish se behtar."
