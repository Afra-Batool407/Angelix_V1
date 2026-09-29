extends RefCounted
class_name AngelBrain
## Offline "brain" for Angel. No API keys, no hosted LLM, no network.
##
## Detects intents via weighted keyword/phrase matching (English + Roman Urdu)
## and picks a supportive reply + mood. Reviewed replies come from the topic
## JSON's `angel_replies`; built-in fallbacks cover the rest. Unknown input
## always receives a friendly clarification, never a fabricated answer.
##
## Mood -> animation note: the Angel model in this project has NO imported
## AnimationPlayer clips (verified: scenes/angel.tscn contains no
## AnimationPlayer; scripts/angel.gd is fully procedural). Moods are therefore
## mapped to verified procedural visual states by lesson.gd via a string
## ("happy" | "thinking" | "excited" | "neutral"), with "neutral" as the safe
## fallback for any unknown mood.

const MOODS := ["happy", "thinking", "excited", "neutral"]

## Intent weights: phrase fragments -> weight. Longer/more specific phrases
## carry more weight so "dobara samjhao" beats a lone "samjhao".
const INTENT_KEYWORDS := {
	"explain_again": {
		"dobara samjhao": 5.0, "dobara samjha": 5.0, "phir samjhao": 5.0,
		"explain again": 5.0, "explain it again": 6.0, "samjhao dobara": 5.0,
		"once more": 3.0, "repeat": 3.0, "dobara": 2.0, "samjhao": 2.0,
		"explain": 2.0, "samjha": 1.5, "again please": 3.0,
	},
	"give_hint": {
		"hint": 6.0, "hint do": 7.0, "koi hint": 7.0, "help me": 4.0,
		"madad": 4.0, "help": 2.5, "mushkil": 2.0, "stuck": 3.0,
		"atta nahi": 3.0, "nhi ata": 3.0, "confused": 2.0,
	},
	"quiz_me": {
		"test lo": 7.0, "quiz": 6.0, "quiz do": 7.0, "test do": 6.0,
		"test": 4.0, "mcq": 5.0, "questions pucho": 5.0, "ask me": 4.0,
		"start quiz": 7.0, "exam": 3.0, "check me": 3.0,
	},
	"why_wrong": {
		"why wrong": 6.0, "ghalat kyun": 6.0, "ghalat kio": 6.0,
		"why is it wrong": 6.0, "why not": 3.0, "kyun ghalat": 5.0,
		"mistake": 3.0, "ghalat kaha": 5.0, "why incorrect": 5.0,
		"where did i go wrong": 7.0,
	},
	"encouragement": {
		"mushkil hai": 3.0, "i can't": 4.0, "nahi ho raha": 4.0,
		"nh ho raha": 4.0, "give up": 4.0, "himmat": 4.0,
		"depress": 4.0, "difficult": 2.5, "hard hai": 3.5, "tired": 3.0,
		"thak gaya": 4.0, "boring": 2.0,
	},
	"smalltalk": {
		"hello": 4.0, "hi": 3.0, "assalam": 5.0, "salam": 4.0,
		"kaise ho": 5.0, "kya haal": 5.0, "how are you": 5.0,
		"tum kaun": 5.0, "who are you": 4.0, "thanks": 3.0, "shukriya": 4.0,
		"good morning": 3.0, "bye": 2.0, "khuda hafiz": 3.0,
	},
	"switch_language": {
		"urdu mein": 6.0, "roman urdu": 6.0, "in urdu": 5.0,
		"english mein": 6.0, "in english": 5.0, "urdu karo": 6.0,
		"english karo": 6.0, "translate": 3.0, "language": 2.0,
	},
}

const FALLBACKS := {
	"explain_again": "Chalo, main dobara samjhati hoon! %s",
	"give_hint": "Yeh lo ek hint: %s",
	"quiz_me": "Test time! %s",
	"why_wrong": "Koi baat nahi, galti se hi seekhte hain. %s",
	"encouragement": "Himmat rakho! %s",
	"smalltalk": "%s",
	"switch_language": "Theek hai, main English aur Roman Urdu dono samajh sakti hoon! %s",
	"unclear": "Sorry, yeh samajh nahi aya. Aap 'dobara samjhao', 'hint do', 'test lo' ya 'why wrong' keh sakti hain — ya apna sawal thoda aur clearly likho.",
}

var topic_title := ""
var _replies_by_intent := {}
var _last_reply_ids := {}


## topic_data: full parsed topic JSON Dictionary (may be empty for safety).
func setup(topic_data: Dictionary) -> void:
	_replies_by_intent.clear()
	_last_reply_ids.clear()
	topic_title = String(topic_data.get("title", "this topic"))
	var replies: Variant = topic_data.get("angel_replies", [])
	if replies is Array:
		for r in replies:
			if r is Dictionary and r.has("intent") and r.has("text"):
				var intent := String(r["intent"])
				if not _replies_by_intent.has(intent):
					_replies_by_intent[intent] = []
				_replies_by_intent[intent].append(r)


## Returns { "intent": String, "mood": String, "text": String, "reply_id": String }
func respond(user_text: String, context: Dictionary = {}) -> Dictionary:
	var intent := detect_intent(user_text)
	# A student who has just missed several answers and types something
	# unclear probably needs a hint more than a clarification.
	var streak := int(context.get("wrong_streak", 0))
	if intent == "unclear" and streak >= 2:
		intent = "give_hint"
	var mood := "neutral"
	var text := ""
	var reply_id := ""

	# Prefer a reviewed reply from the topic JSON for this intent.
	var candidates: Array = _replies_by_intent.get(intent, [])
	var reply := _pick_reply(candidates)
	if not reply.is_empty():
		text = String(reply["text"])
		reply_id = String(reply.get("id", ""))
		mood = _verified_mood(String(reply.get("mood", "neutral")))
	else:
		# Built-in fallback, enriched with topic context where useful.
		var tmpl := String(FALLBACKS.get(intent, FALLBACKS["unclear"]))
		var seed_text := _context_line(intent, context)
		text = tmpl % seed_text if tmpl.contains("%s") else tmpl
		mood = _default_mood(intent)
		reply_id = "fallback." + intent

	# Quiz-result context can override mood for extra warmth.
	if context.has("quiz_score") and intent in ["encouragement", "why_wrong"]:
		var score := int(context["quiz_score"])
		if score >= 3:
			mood = "excited"
		elif score <= 1:
			mood = "neutral"

	return {"intent": intent, "mood": mood, "text": text, "reply_id": reply_id}


## Weighted keyword/phrase detection. Scores each intent by summing weights of
## every phrase contained in the normalized input; highest score wins. A total
## score below 1.5 (or no match at all) returns "unclear".
func detect_intent(user_text: String) -> String:
	var norm := " " + user_text.to_lower().strip_edges()
	norm = norm.replace(",", " ").replace("?", " ").replace("!", " ")
	norm = norm.replace(".", " ").replace("  ", " ").strip_edges()
	if norm.is_empty():
		return "unclear"

	var best_intent := "unclear"
	var best_score := 0.0
	for intent in INTENT_KEYWORDS:
		var phrases: Dictionary = INTENT_KEYWORDS[intent]
		var score := 0.0
		for phrase in phrases:
			if norm.findn(String(phrase)) != -1:
				score += float(phrases[phrase])
		if score > best_score:
			best_score = score
			best_intent = String(intent)

	if best_score < 1.5:
		return "unclear"
	return best_intent


## Round-robin through the candidate replies so repeat asks vary.
func _pick_reply(candidates: Array) -> Dictionary:
	if candidates.is_empty():
		return {}
	var intent := String(candidates[0].get("intent", "?"))
	var idx := int(_last_reply_ids.get(intent, -1)) + 1
	if idx >= candidates.size():
		idx = 0
	_last_reply_ids[intent] = idx
	var reply: Dictionary = candidates[idx]
	return reply if reply.has("text") else {}


func _verified_mood(mood: String) -> String:
	return mood if mood in MOODS else "neutral"


func _default_mood(intent: String) -> String:
	match intent:
		"quiz_me":
			return "excited"
		"give_hint", "why_wrong":
			return "thinking"
		"explain_again", "encouragement":
			return "happy"
		_:
			return "neutral"


## A short topic-aware seed line for fallback replies.
func _context_line(intent: String, context: Dictionary) -> String:
	var subject := topic_title
	var last_wrong := String(context.get("last_wrong_topic_point", ""))
	match intent:
		"explain_again":
			return "Real numbers = rationals (decimals stop ya repeat hote hain) + irrationals (kabhi stop nahi hote, jaise sqrt(2)). " + subject + " ka number line wala part yaad rakho."
		"give_hint":
			return "poochho khud se — decimal STOP karta hai, REPEAT karta hai, ya FOREVER chalta hai? Pehla do = rational, teesra = irrational." if last_wrong == "" else "Is dafa " + last_wrong + " par dhyan do — decimal stop karta hai ya repeat?"
		"quiz_me":
			return "3 questions hain, " + subject + " se hi. Ready? Chalo shuru!"
		"why_wrong":
			return "Ek nazar check karo: kya decimal terminate ya repeat ho raha tha? Wahi rational aur irrational ka farq hai."
		"encouragement":
			return "Yeh topic mushkil lagta hai par tum ne sab se mushkil hissa already parh liya hai. Ek step aur!"
		"smalltalk":
			return "Main Angel hoon, aapki study buddy. Chalo " + subject + " par kaam karein."
		"switch_language":
			return "Aap Urdu ya English mein likh sakti hain."
		_:
			return ""


## ---------------------------------------------------------------- checkpoints
## Checkpoint answer matching for the presentation lesson. Normalizes
## English/Roman Urdu input, matches against the checkpoint's reviewed
## accepted_answers, and returns the checkpoint's own feedback text. Unknown
## answers get the reviewed retry feedback — never a fabricated explanation.
func check_checkpoint_answer(answer: String, checkpoint: Dictionary) -> Dictionary:
	var norm := _normalize_answer(answer)
	if norm.is_empty():
		return {"correct": false, "mood": "neutral",
			"text": String(checkpoint.get("retry_feedback",
				"Kuch likho — try again!"))}
	for accepted: Variant in (checkpoint.get("accepted_answers", []) as Array):
		if accepted is String and _answer_matches(norm, _normalize_answer(accepted)):
			return {"correct": true, "mood": "happy",
				"text": String(checkpoint.get("correct_feedback", ""))}
	return {"correct": false, "mood": "thinking",
		"text": String(checkpoint.get("retry_feedback", ""))}


func _normalize_answer(answer: String) -> String:
	var norm := answer.to_lower().strip_edges()
	for ch: String in [",", "?", "!", ".", ";", ":", "\"", "'"]:
		norm = norm.replace(ch, " ")
	while norm.contains("  "):
		norm = norm.replace("  ", " ")
	return norm.strip_edges()


func _answer_matches(answer: String, accepted: String) -> bool:
	if accepted.is_empty():
		return false
	return answer == accepted or answer.contains(accepted) or accepted.contains(answer)
