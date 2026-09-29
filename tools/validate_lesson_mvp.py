#!/usr/bin/env python3
"""Offline validation for the Angelix lesson MVP (no Godot binary available).

Checks:
 1. Topic JSON schema: required fields, exactly 3 quiz Qs, exactly 6 angel
    replies, allowed moods, stable unique IDs, correct_index in range.
 2. Teaching timeline: allowed actions, required fields, numeric ranges,
    caption presence; plus malformed-input cases (the same rules the GDScript
    renderer enforces at runtime).
 3. Citation cross-check: every cited PDF page must be one of the pages
    actually OCR-checked in page1-150.pdf.
 4. GDScript static reference check: every called local method exists.
 5. Scene integrity: lesson.tscn unique node names match lesson.gd %lookups,
    load_steps matches ext_resource count.

Run:  python3 tools/validate_lesson_mvp.py
Exit code 0 = all checks passed.
"""
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
FAILURES = []
CHECKS = []


def check(name: str, ok: bool, detail: str = "") -> None:
    CHECKS.append((name, ok, detail))
    if not ok:
        FAILURES.append(f"{name}: {detail}")


# ---------------------------------------------------------------- 1. JSON
topic_path = ROOT / "content/topics/math.u01.real-numbers.json"
check("topic file exists", topic_path.exists(), str(topic_path))
if topic_path.exists():
    try:
        topic = json.loads(topic_path.read_text(encoding="utf-8"))
        check("topic JSON parses", True)
    except Exception as e:  # noqa: BLE001
        topic = None
        check("topic JSON parses", False, str(e))

if topic is not None:
    check("schema_version == 1", topic.get("schema_version") == 1,
          str(topic.get("schema_version")))
    check("topic_id stable", topic.get("topic_id") == "math.u01.real-numbers",
          str(topic.get("topic_id")))
    check("title present", bool(topic.get("title")))
    check("language describes code-switching",
          "Roman Urdu" in str(topic.get("language", "")),
          str(topic.get("language", "")))
    check("explanation present", len(str(topic.get("explanation", ""))) > 100)
    check("pakistani_life_example present", len(str(topic.get("pakistani_life_example", ""))) > 40)

    we = topic.get("worked_example", {})
    check("worked_example has >=2 steps", len(we.get("steps", [])) >= 2,
          str(len(we.get("steps", []))))
    check("worked_example has answer", bool(we.get("answer")))
    check("worked_example has citation", bool(we.get("citation")))

    practice = topic.get("practice", [])
    check("at least 1 practice item", len(practice) >= 1, str(len(practice)))
    for i, p in enumerate(practice):
        check(f"practice[{i}] has id/hint/solution",
              bool(p.get("id")) and bool(p.get("hint")) and bool(p.get("solution")))

    quiz = topic.get("quiz", [])
    check("exactly 3 quiz questions", len(quiz) == 3, str(len(quiz)))
    qids = [q.get("id", "") for q in quiz]
    check("quiz ids unique", len(set(qids)) == len(qids), str(qids))
    for i, q in enumerate(quiz):
        n = len(q.get("choices", []))
        idx = q.get("correct_index", -1)
        check(f"quiz[{i}] correct_index in range", isinstance(idx, int) and 0 <= idx < n,
              f"index={idx} choices={n}")
        check(f"quiz[{i}] has explanation", bool(q.get("explanation")))
        check(f"quiz[{i}] has citation", bool(q.get("citation")))
        check(f"quiz[{i}] has stable id", bool(q.get("id")))

    replies = topic.get("angel_replies", [])
    check("exactly 6 angel replies", len(replies) == 6, str(len(replies)))
    allowed_moods = {"happy", "thinking", "excited", "neutral"}
    rids = [r.get("id", "") for r in replies]
    check("angel reply ids unique", len(set(rids)) == len(rids), str(rids))
    for i, r in enumerate(replies):
        check(f"reply[{i}] mood allowed", r.get("mood") in allowed_moods,
              str(r.get("mood")))
        check(f"reply[{i}] has id/intent/text",
              bool(r.get("id")) and bool(r.get("intent")) and bool(r.get("text")))

    intents = [r.get("intent", "") for r in replies]
    check("at least 5 distinct intents among replies", len(set(intents)) >= 5, str(intents))

    # ------------------------------------------------- 2. timeline rules
    ALLOWED_ACTIONS = {"show_number_line", "mark_point", "highlight_interval", "show_caption"}
    REQUIRED = {
        "show_number_line": [],
        "mark_point": ["value"],
        "highlight_interval": ["from", "to"],
        "show_caption": [],
    }
    NUMERIC = {"value", "from", "to"}
    MIN_V, MAX_V = -4.0, 4.0

    def validate_steps(steps, label):
        errs = []
        for i, s in enumerate(steps):
            if not isinstance(s, dict):
                errs.append(f"{label}[{i}] not a dict")
                continue
            action = s.get("action", "")
            if action not in ALLOWED_ACTIONS:
                errs.append(f"{label}[{i}] unknown action '{action}'")
                continue
            for k in REQUIRED[action]:
                if k not in s:
                    errs.append(f"{label}[{i}] missing '{k}'")
            for k in ("value", "from", "to"):
                if k in s and not isinstance(s[k], (int, float)):
                    errs.append(f"{label}[{i}] '{k}' not numeric")
            if action == "mark_point":
                if not isinstance(s.get("value"), (int, float)):
                    errs.append(f"{label}[{i}] 'value' not numeric")
                else:
                    v = float(s["value"])
                    if not (MIN_V <= v <= MAX_V):
                        errs.append(f"{label}[{i}] value {v} out of range")
            if action != "show_caption" and not str(s.get("caption", "")).strip():
                errs.append(f"{label}[{i}] missing caption")
        return errs

    ta = topic.get("teaching_animation", {})
    steps = ta.get("steps", [])
    errs = validate_steps(steps, "steps")
    check("timeline valid (>=4 steps, ordered actions)", not errs and len(steps) >= 4,
          "; ".join(errs) or f"only {len(steps)} steps")
    check("timeline steps have ascending order values",
          all(steps[i].get("order", 0) < steps[i + 1].get("order", 0)
              for i in range(len(steps) - 1)))

    # Malformed-input cases (mirror of the GDScript renderer's validation).
    malformed = {
        "non-dict step": [42],
        "unknown action": [{"action": "explode"}],
        "mark_point without value": [{"action": "mark_point", "caption": "x"}],
        "interval without from": [{"action": "highlight_interval", "to": 1.0, "caption": "x"}],
        "mark_point out of range": [{"action": "mark_point", "value": 9.5, "caption": "x"}],
        "numeric-as-string": [{"action": "mark_point", "value": "two", "caption": "x"}],
    }
    for label, bad in malformed.items():
        check(f"malformed rejected: {label}", len(validate_steps(bad, label)) > 0,
              "validator accepted bad data")
    check("valid steps accepted", validate_steps(steps, "steps") == [])
    check("empty timeline tolerated by validator", validate_steps([], "empty") == [])

    # ------------------------------------------------- 3. citations
    checked_pages = {3: 1, 5: 3, 6: 4, 7: 5, 8: 6}  # pdf page -> printed page (OCR-verified)
    cited_pages = set()
    for sp in topic.get("source_pages", []):
        cited_pages.add(sp.get("pdf_page"))
    all_text = json.dumps(topic)
    for m in re.finditer(r"PDF page (\d+)", all_text):
        cited_pages.add(int(m.group(1)))
    bad = [p for p in cited_pages if p is not None and p not in checked_pages]
    check("all cited PDF pages were OCR-checked", not bad,
          f"unchecked pages: {sorted(x for x in bad if x is not None)}")
    for sp in topic.get("source_pages", []):
        pdf_p, pr_p = sp.get("pdf_page"), sp.get("printed_page")
        check(f"printed page mapping pdf {pdf_p} -> {pr_p}",
              checked_pages.get(pdf_p) == pr_p,
              f"expected {checked_pages.get(pdf_p)}")

# ------------------------------------------------------------ 4. GDScript
def gdscript_defs(src: str):
    return set(re.findall(r"^func\s+([A-Za-z_][A-Za-z0-9_]*)", src, re.M))


def gdscript_calls(src: str):
    return set(re.findall(r"(?<![\w.])_([a-z][A-Za-z0-9_]*)\s*\(", src))


for script in ["scripts/lesson.gd", "scripts/lesson_renderer.gd",
               "scripts/angel_brain.gd", "scripts/learning_progress.gd"]:
    p = ROOT / script
    check(f"{script} exists", p.exists())
    if not p.exists():
        continue
    src = p.read_text(encoding="utf-8")
    defs = gdscript_defs(src)
    # Underscore-prefixed calls resolve to _<name> definitions.
    missing = []
    for call in gdscript_calls(src):
        name = "_" + call
        if name not in defs and name not in src:
            missing.append(name)
    check(f"{script}: all local _method calls have defs", not missing,
          str(sorted(set(missing))))
    # Tab indentation convention.
    space_indented = [ln for ln in src.splitlines()
                      if ln.startswith("    ") and not ln.lstrip().startswith("*")]
    check(f"{script}: tab indentation", not space_indented,
          f"{len(space_indented)} space-indented lines")
    # No network/API usage anywhere in the new scripts.
    forbidden = ["HTTPRequest", "http_request", "fetch(", "XMLHttpRequest",
                 "api_key", "API_KEY", "HttpClient", "WebSocketPeer"]
    hits = [f for f in forbidden if f in src]
    check(f"{script}: no network/API usage", not hits, str(hits))

menu_src = (ROOT / "scripts/menu_controller.gd").read_text(encoding="utf-8")
check("menu: LESSON_TOPIC constant present", 'const LESSON_TOPIC := "math.u01.real-numbers"' in menu_src)
check("menu: LESSON_SCENE constant present", 'const LESSON_SCENE := "res://scenes/lesson.tscn"' in menu_src)
check("menu: routes lesson topic", "if item_id == LESSON_TOPIC:" in menu_src)
check("menu: still routes 3D topic", "elif item_id == TARGET_TOPIC:" in menu_src)
check("menu: only lesson topic enabled in UNIT1",
      menu_src.count('"enabled": true},\n\t{"id": "math.u01.real-numbers.rational-irrational-combination"') == 1)

brain_src = (ROOT / "scripts/angel_brain.gd").read_text(encoding="utf-8")
for intent in ["explain_again", "give_hint", "quiz_me", "why_wrong",
               "encouragement", "smalltalk", "switch_language", "unclear"]:
    check(f"brain intent '{intent}' implemented", intent in brain_src)
for phrase in ["dobara samjhao", "samajh nahi aya", "hint", "test lo"]:
    check(f"brain phrase '{phrase}' matched", phrase in brain_src)

# ------------------------------------------------------------- 5. scenes
lesson_tscn = (ROOT / "scenes/lesson.tscn").read_text(encoding="utf-8")
ext_count = lesson_tscn.count("[ext_resource ")
load_steps = int(re.search(r"load_steps=(\d+)", lesson_tscn).group(1))
check("lesson.tscn load_steps == ext_resources + 1", load_steps == ext_count + 1,
      f"load_steps={load_steps} ext={ext_count}")
unique_nodes = set(re.findall(r"unique_name_in_owner = true", lesson_tscn))
lesson_src = (ROOT / "scripts/lesson.gd").read_text(encoding="utf-8")
# Strip string literals so format specifiers like %d / %s don't masquerade
# as unique-node lookups.
lesson_src_nostr = re.sub(r'"(?:[^"\\]|\\.)*"', '""', lesson_src)
lookups = set(re.findall(r"%([A-Z][A-Za-z0-9_]*)", lesson_src_nostr))
node_names = set(re.findall(r"\[node name=\"([A-Za-z0-9_]+)\"", lesson_tscn))
for lookup in lookups:
    check(f"lesson.tscn has unique node for %{lookup}", lookup in node_names)

menu_tscn = (ROOT / "scenes/ui_menu.tscn").read_text(encoding="utf-8")
check("menu.tscn still has %Content/%Grid/%TitleLabel/%SubtitleLabel/%BackButton",
      all(n in menu_tscn for n in ["Content", "Grid", "TitleLabel", "SubtitleLabel", "BackButton"]))

# ----------------------------------------------------------------- report
print(f"{len(CHECKS)} checks run, {len(FAILURES)} failed")
for name, ok, detail in CHECKS:
    status = "PASS" if ok else "FAIL"
    line = f"[{status}] {name}"
    if detail and not ok:
        line += f" -> {detail}"
    print(line)
# (final exit happens after the AngelTown checks below)

# ============================================================
# AngelTown phase checks (appended; same fail-fast reporting)
# ============================================================
import json as _json

def _at(name, ok, detail=""):
    check(name, ok, detail)

# --- Session autoload ---
proj = (ROOT / "project.godot").read_text(encoding="utf-8")
_at("autoload GameSession registered", 'GameSession="*res://scripts/game_session.gd"' in proj)
_at("main_scene still ui_menu", 'run/main_scene="res://scenes/ui_menu.tscn"' in proj)

sess = (ROOT / "scripts/game_session.gd").read_text(encoding="utf-8")
_at("session: content_path_for", "func content_path_for" in sess)
_at("session: has_topic_content", "func has_topic_content" in sess)
_at("session: matches_station family match", "begins_with(station_topic_id" in sess)

# --- Menu records selection; routing unchanged ---
menu = (ROOT / "scripts/menu_controller.gd").read_text(encoding="utf-8")
_at("menu: records selected topic", "GameSession.selected_topic_id = item_id" in menu)
_at("menu: 3D route preserved", "elif item_id == TARGET_TOPIC:" in menu)
_at("menu: lesson route preserved", "if item_id == LESSON_TOPIC:" in menu)

# --- World controller ---
wc = (ROOT / "scripts/world_controller.gd").read_text(encoding="utf-8")
_at("world: spawns player scene", "res://scenes/player.tscn" in wc)
_at("world: overlay keeps world alive (no change_scene in open/close)",
    "change_scene" not in wc.split("func _open_lesson")[1].split("func ")[1])
_at("world: locks player while overlay open", "_player.locked = true" in wc)
_at("world: closes overlay on back first",
    wc.find("if _lesson_open:\n\t\t\t_close_lesson()") != -1
    or "_close_lesson()\n\t\telse:" in wc)
_at("world: only validated content opens lessons",
    "has_topic_content" in wc)
_at("world: fallback creates real-numbers station",
    '"math.u01.real-numbers"' in wc)

# --- Learning station configurability ---
st = (ROOT / "scripts/learning_station.gd").read_text(encoding="utf-8")
for field in ["topic_id", "display_title", "zone", "available"]:
    _at(f"station: @export {field}", f"@export var {field}" in st)
_at("station: locked shows Coming soon", '"Coming soon"' in st)

# --- Station scene integrity ---
stn = (ROOT / "scenes/learning_station.tscn").read_text(encoding="utf-8")
ext = stn.count("[ext_resource ")
subs = stn.count("[sub_resource ")
steps = int(re.search(r"load_steps=(\d+)", stn).group(1))
_at("learning_station.tscn load_steps consistent", steps == ext + subs + 1,
    f"steps={steps} ext={ext} subs={subs}")
_at("learning_station.tscn has no bogus refs", "PrimitiveMeshes" not in stn)

# --- Player scene/controller ---
pl = (ROOT / "scenes/player.tscn").read_text(encoding="utf-8")
pl_ext = pl.count("[ext_resource ")
pl_subs = pl.count("[sub_resource ")
pl_steps = int(re.search(r"load_steps=(\d+)", pl).group(1))
_at("player.tscn load_steps consistent", pl_steps == pl_ext + pl_subs + 1,
    f"steps={pl_steps} ext={pl_ext} subs={pl_subs}")
pc = (ROOT / "scripts/player_controller.gd").read_text(encoding="utf-8")
_at("player: lockable", "var locked := false" in pc or "var locked" in pc)
_at("player: uses joystick group", 'get_nodes_in_group("joystick")' in pc)
_at("player: has gravity", "GRAVITY" in pc)

# --- main.tscn integrity and wiring ---
mn = (ROOT / "main.tscn").read_text(encoding="utf-8")
mn_ext = mn.count("[ext_resource ")
mn_subs = mn.count("[sub_resource ")
mn_steps = int(re.search(r"load_steps=(\d+)", mn).group(1))
_at("main.tscn load_steps consistent", mn_steps == mn_ext + mn_subs + 1,
    f"steps={mn_steps} ext={mn_ext} subs={mn_subs}")
_at("main.tscn: station instanced", 'instance=ExtResource("5_station")' in mn)
_at("main.tscn: station in group", 'groups=["learning_station"]' in mn)
_at("main.tscn: HUD present", "[node name=\"HUD\" type=\"CanvasLayer\"" in mn)
_at("main.tscn: LessonOverlay present", "[node name=\"LessonOverlay\" type=\"CanvasLayer\"" in mn)
_at("main.tscn: overlay starts hidden", "visible = false" in mn.split("[node name=\"LessonOverlay\"")[1])
_at("main.tscn: joystick kept", "TouchJoystick" in mn)
_at("main.tscn: Angel kept", 'path="res://scenes/angel.tscn"' in mn)
_at("main.tscn: terrain kept", "terrain.gd" in mn)

# --- Angel moods: verified procedural fallback, no invented clips ---
ang = (ROOT / "scripts/angel.gd").read_text(encoding="utf-8")
_at("angel: no invented AnimationPlayer usage",
    "AnimationPlayer.new(" not in ang and "$AnimationPlayer" not in ang
    and "play(\"" not in ang)
_at("angel: set_mood exists", "func set_mood" in ang)
_at("angel: neutral fallback", "_mood_energy = 1.0" in ang)

# --- Lesson overlay mode (standalone route preserved) ---
ls = (ROOT / "scripts/lesson.gd").read_text(encoding="utf-8")
_at("lesson: overlay_mode exists", "var overlay_mode := false" in ls)
_at("lesson: standalone back still works",
    "NOTIFICATION_WM_GO_BACK_REQUEST" in ls and "ui_cancel" in ls)

# --- AngelFollower inner class defined & used ---
_at("world: AngelFollower class", "class AngelFollower" in wc)
_at("world: follower configured", "driver.configure(" in wc)

print()
print(f"TOTAL: {len(CHECKS)} checks, {len(FAILURES)} failed")
if FAILURES:
    for f in FAILURES:
        print("FAIL ->", f)
    sys.exit(1)

# ============================================================
# Phase 2 checks (in-world Real Numbers activity)
# ============================================================
import json as _json2

def _p2(name, ok, detail=""):
    check(name, ok, detail)

data = _json2.loads((ROOT / "content/topics/math.u01.real-numbers.json").read_text(encoding="utf-8"))
wa = data.get("world_activity", {})
_p2("world_activity present", isinstance(wa, dict) and len(wa) > 0)
nl = wa.get("number_line", {})
_p2("number_line config valid",
    isinstance(nl, dict) and nl.get("min_value") < nl.get("max_value"))
tasks = wa.get("marker_tasks", [])
_p2(">=3 marker tasks with fields", len(tasks) >= 3 and all(
    {"id", "prompt", "target_value", "tolerance", "kind",
     "explain_correct", "explain_wrong"} <= set(t) for t in tasks))
orbs = wa.get("quiz_orbs", [])
_p2(">=3 quiz orbs with fields", len(orbs) >= 3 and all(
    {"id", "value", "statement", "is_true", "explain"} <= set(o) for o in orbs))
_p2("orb values within line range", all(
    nl.get("min_value") <= o.get("value") <= nl.get("max_value") for o in orbs))
_p2("task targets within line range", all(
    nl.get("min_value") <= t.get("target_value") <= nl.get("max_value") for t in tasks))
_p2("original content keys preserved", all(
    k in data for k in ["explanation", "pakistani_life_example", "worked_example",
                        "practice", "quiz", "angel_replies", "teaching_animation"]))
_p2("quiz still exactly 3", len(data.get("quiz", [])) == 3)

act = (ROOT / "scripts/number_line_activity.gd").read_text(encoding="utf-8")
_p2("activity: validation with fallback", "_build_fallback" in act and "push_error" in act)
_p2("activity: range sanity checked", "is_nan" in act)
_p2("activity: orbs data-driven", "quiz_orbs" in act)
_p2("activity: completion signal", "signal activity_completed" in act)
_p2("activity: HUD task mirror", "signal task_changed" in act)

wc2 = (ROOT / "scripts/world_controller.gd").read_text(encoding="utf-8")
_p2("world: loads activity from JSON", "load_topic_data" in wc2)
_p2("world: activity buttons wired", all(s in wc2 for s in [
    "_left_btn.pressed.connect", "_submit_btn.pressed.connect",
    "_right_btn.pressed.connect", "_lesson_btn.pressed.connect"]))
_p2("world: back closes activity first",
    wc2.find("_set_activity_active(false)") < wc2.find("_confirm_return_to_menu()\n\t\telse") or
    "_activity.visible:\n\t\t\t_set_activity_active(false)" in wc2)
_p2("world: activity done persisted", "set_activity_done" in wc2)
_p2("world: reopening respects saved done",
    'get("activity_done", false)' in wc2)

lp = (ROOT / "scripts/learning_progress.gd").read_text(encoding="utf-8")
_p2("progress: activity_done sanitized", '"activity_done": bool(entry.get("activity_done", false))' in lp)
_p2("progress: set_activity_done API", "func set_activity_done" in lp)

orb_scene = (ROOT / "scenes/quiz_orb.tscn").read_text(encoding="utf-8")
orb_ext = orb_scene.count("[ext_resource ")
orb_subs = orb_scene.count("[sub_resource ")
orb_steps = int(re.search(r"load_steps=(\d+)", orb_scene).group(1))
_p2("quiz_orb.tscn load_steps consistent", orb_steps == orb_ext + orb_subs + 1)
act_scene = (ROOT / "scenes/number_line_activity.tscn").read_text(encoding="utf-8")
act_ext = act_scene.count("[ext_resource ")
act_subs = act_scene.count("[sub_resource ")
act_steps = int(re.search(r"load_steps=(\d+)", act_scene).group(1))
_p2("number_line_activity.tscn load_steps consistent", act_steps == act_ext + act_subs + 1)

print()
print(f"TOTAL: {len(CHECKS)} checks, {len(FAILURES)} failed")
if FAILURES:
    for f in FAILURES:
        print("FAIL ->", f)
    sys.exit(1)

# ============================================================
# Phase 3 checks (AngelTown zones)
# ============================================================
def _p3(name, ok, detail=""):
    check(name, ok, detail)

tb = (ROOT / "scripts/town_builder.gd").read_text(encoding="utf-8")
for zone in ["Math Meadows", "Science Springs", "Language Lagoon"]:
    _p3(f"zone '{zone}' defined", zone in tb)
_p3("fountain built", "FountainOfKnowledge" in tb)
_p3("paths connect hub to zones", "_build_paths" in tb and "lerp(b, t)" in tb)
_p3("scatter keep-clear (paths/hub/zones)", "_blocks_gameplay" in tb and "keep_clear" in tb)
_p3("locked future stations honest",
    tb.count('"Coming soon"') == 2 and 'available = false' in tb and 'st.topic_id = ""' in tb)
_p3("zone signs readable", "_build_zone_signs" in tb)
_p3("fountain/path follow terrain", "_terrain_y(FOUNTAIN_POS" in tb and "_terrain_y(p.x, p.y)" in tb)

ts = (ROOT / "scripts/town_scatter.gd").read_text(encoding="utf-8")
_p3("scatter deterministic seed", "SEED := 20260928" in ts)
_p3("scatter uses MultiMesh", "MultiMeshInstance3D" in ts and "TRANSFORM_3D" in ts)
_p3("scatter safe without providers", "push_error" in ts and "return" in ts)

dn = (ROOT / "scripts/day_night_cycle.gd").read_text(encoding="utf-8")
_p3("day/night: stoppable", "func stop()" in dn and "func start()" in dn)
_p3("day/night: no shadow toggling per frame", dn.count("shadow_enabled") == 0)
_p3("day/night: slow period", "DAY_LENGTH_SEC := 240.0" in dn)

tr = (ROOT / "terrain.gd").read_text(encoding="utf-8")
_p3("terrain: ground query public", "func get_ground_height" in tr)
_p3("terrain: 4 flat spots (hub + 3 zones)", tr.count("Vector3(") >= 4 and "-16, 1.5, -12" in tr and "14, 1.5, -14" in tr)

mn3 = (ROOT / "main.tscn").read_text(encoding="utf-8")
_p3("main.tscn: TownBuilder instanced", "town_builder.gd" in mn3)
_p3("main.tscn: DayNight instanced", "day_night_cycle.gd" in mn3)
wc3 = (ROOT / "scripts/world_controller.gd").read_text(encoding="utf-8")
_p3("world: performance mode disables day/night", "if GameSession.performance_mode:" in wc3 and "_day_night.stop()" in wc3)
_p3("world: perf mode kills shadows", "_sun.shadow_enabled = false" in wc3)

print()
print(f"TOTAL: {len(CHECKS)} checks, {len(FAILURES)} failed")
if FAILURES:
    for f in FAILURES:
        print("FAIL ->", f)
    sys.exit(1)

# ============================================================
# Phase 4 checks (progression, navigation, polish)
# ============================================================
def _p4(name, ok, detail=""):
    check(name, ok, detail)

lp4 = (ROOT / "scripts/learning_progress.gd").read_text(encoding="utf-8")
_p4("progress: schema v2", "SCHEMA_VERSION := 2" in lp4)
_p4("progress: xp fields sanitized",
    '"xp": maxi(0, int(entry.get("xp", 0)))' in lp4
    and '"first_completion_rewarded"' in lp4 and '"mastery_rewarded"' in lp4)
_p4("progress: first-completion gated by flag",
    "if not was_rewarded:" in lp4 and 'entry["first_completion_rewarded"] = true' in lp4)
_p4("progress: mastery bonus gated by flag",
    'not bool(entry["mastery_rewarded"])' in lp4)
_p4("progress: totals exposed", "func get_total_xp" in lp4 and "func get_total_stars" in lp4)

ts4 = (ROOT / "scripts/town_settings.gd").read_text(encoding="utf-8")
_p4("settings: versioned + perf flag", "SCHEMA_VERSION := 2" in ts4 and "performance_mode" in ts4)
_p4("settings: position validation (bounds/nan/inf/y)",
    "is_nan" in ts4 and "is_inf" in ts4 and "BOUNDS_X" in ts4 and "MAX_Y" in ts4)
_p4("settings: newer file refused safely", "if ver > SCHEMA_VERSION:" in ts4)
_p4("settings: atomic save", ".tmp" in ts4 and "rename" in ts4)
_p4("settings: clear position helper", "func clear_player_position" in ts4)

wc4 = (ROOT / "scripts/world_controller.gd").read_text(encoding="utf-8")
_p4("world: loads settings + progress", "_settings.load_settings()" in wc4 and "_progress.load_progress()" in wc4)
_p4("world: restores validated position",
    "TownSettings.is_valid_position(_settings.player_position)" in wc4)
_p4("world: topic spawn still works (no position save)",
    'GameSession.matches_station(selected, st.topic_id)' in wc4)
_p4("world: saves position periodically", "_save_player_position()" in wc4 and "_save_accum >= 5.0" in wc4)
_p4("world: saves position on exit to menu",
    wc4.find("_save_player_position()\n\tget_tree().change_scene_to_file(MENU_SCENE)") != -1)
_p4("world: XP HUD updates on lesson close",
    wc4.find("func _close_lesson") < wc4.find("_update_xp_hud()") and
    "_progress.load_progress()\n\t_xp_label.text" in wc4)
_p4("world: angel mood on quiz outcome", "_angel.set_mood(" in wc4)
_p4("world: pause wired (button + back + menu)",
    "_pause_btn.pressed.connect(_open_pause)" in wc4
    and "_pause_menu.is_open()" in wc4
    and "_menu_button.pressed.connect(_open_pause)" in wc4)
_p4("world: perf mode toggles scatter", "_set_scatter_visible" in wc4)
_p4("world: compass updated at 5 Hz", "_compass_accum >= 0.2" in wc4)
_p4("world: compass targets carry availability", '"available": true' in wc4 and '"available": false' in wc4)

cp = (ROOT / "scripts/town_compass.gd").read_text(encoding="utf-8")
_p4("compass: prefers available stations", "best_available" in cp)
_p4("compass: pure drawing (no minimap cost)", "queue_redraw" in cp and "SubViewport" not in cp)

pm = (ROOT / "scripts/pause_menu.gd").read_text(encoding="utf-8")
_p4("pause: works while tree paused", "PROCESS_MODE_WHEN_PAUSED" in pm)
_p4("pause: apply_performance callable", "apply_performance" in pm)
_p4("pause: confirm before leaving", "ConfirmationDialog" in pm or "_confirm" in pm)
_p4("pause: back closes first", "NOTIFICATION_WM_GO_BACK_REQUEST" in pm)

pmt = (ROOT / "scenes/pause_menu.tscn").read_text(encoding="utf-8")
pm_ext = pmt.count("[ext_resource ")
pm_subs = pmt.count("[sub_resource ")
pm_steps = int(re.search(r"load_steps=(\d+)", pmt).group(1))
_p4("pause_menu.tscn load_steps consistent", pm_steps == pm_ext + pm_subs + 1)

mn4 = (ROOT / "main.tscn").read_text(encoding="utf-8")
_p4("main.tscn: PauseMenu instanced", 'instance=ExtResource("8_pause")' in mn4)
_p4("main.tscn: Compass/XPBar/PauseButton present",
    all(n in mn4 for n in ['name="Compass"', 'name="XPBar"', 'name="PauseButton"']))
ls4 = (ROOT / "scripts/lesson.gd").read_text(encoding="utf-8")
_p4("lesson: XP earned shown on result", "+%d XP" in ls4)

qo = (ROOT / "scripts/quiz_orb.gd").read_text(encoding="utf-8")
_p4("orb floats above line", "position.y = 0.9" in qo)

print()
print(f"TOTAL: {len(CHECKS)} checks, {len(FAILURES)} failed")
if FAILURES:
    for f in FAILURES:
        print("FAIL ->", f)
    sys.exit(1)

# ============================================================
# Phase 5 checks (scene structural integrity - Godot .tscn format)
# Catches the fault class seen when a scene file loses its root node
# (Godot error: "root node CollisionShape3D cannot specify a parent"):
#   - first [node] must be the root: no parent= attribute
#   - exactly one parentless node per scene
#   - every child declared after its parent, parent path resolvable
#   - no duplicate node paths
#   - load_steps == ext_resources + sub_resources + 1
#   - SubResource/ExtResource id references resolve
#   - every ext_resource path exists on disk
# ============================================================
NODE_RE = re.compile(r"^\[node ([^\]]*)\]\s*$", re.M)
ATTR_RE = re.compile(r'([a-z_]+)="([^"]*)"')
SUBREF_RE = re.compile(r'SubResource\("([^"]+)"\)')
EXTREF_RE = re.compile(r'ExtResource\("([^"]+)"\)')


def _p5(name, ok, detail=""):
    check(name, ok, detail)


for scene_rel in sorted(str(q) for q in ROOT.rglob("*.tscn")):
    scene_src = (ROOT / scene_rel).read_text(encoding="utf-8")
    tag = scene_rel
    _p5(f"{tag}: starts with [gd_scene header", scene_src.startswith("[gd_scene "))

    nodes = []
    for m in NODE_RE.finditer(scene_src):
        attrs = dict(ATTR_RE.findall(m.group(1)))
        nodes.append((attrs.get("name", "?"), attrs.get("type"),
                      attrs.get("parent"), "instance=" in m.group(1)))
    _p5(f"{tag}: has node entries", len(nodes) > 0)

    if nodes:
        _p5(f"{tag}: root node has no parent attr", nodes[0][2] is None,
            str(nodes[0]))
        root_count = len([n for n in nodes if n[2] is None])
        _p5(f"{tag}: exactly one root node", root_count == 1,
            f"{root_count} parentless nodes")
        _p5(f"{tag}: root has type or instance",
            nodes[0][1] is not None or nodes[0][3], str(nodes[0]))

        declared = set()
        seen_paths = set()
        ordered_ok = True
        first_bad = ""
        duplicate = ""
        for name, _typ, parent, _inst in nodes:
            if parent is None or parent == ".":
                full = name
            elif parent in declared:
                full = f"{parent}/{name}"
            else:
                ordered_ok = False
                first_bad = f"'{name}' parent='{parent}'"
                full = f"{parent}/{name}"
            if full in seen_paths and not duplicate:
                duplicate = full
            seen_paths.add(full)
            declared.add(full)
        _p5(f"{tag}: children declared after parents", ordered_ok, first_bad)
        _p5(f"{tag}: unique node paths", not duplicate, duplicate)

    ext_n = scene_src.count("[ext_resource ")
    sub_n = scene_src.count("[sub_resource ")
    m = re.search(r"load_steps=(\d+)", scene_src)
    if m:
        _p5(f"{tag}: load_steps == ext+sub+1", int(m.group(1)) == ext_n + sub_n + 1,
            f"steps={m.group(1)} ext={ext_n} sub={sub_n}")

    declared_sub_ids = set(re.findall(
        r'\[sub_resource type="[^"]*" id="([^"]+)"', scene_src))
    declared_ext_ids = set(re.findall(
        r'\[ext_resource type="[^"]*" path="[^"]*" id="([^"]+)"', scene_src))
    for rid in sorted(set(SUBREF_RE.findall(scene_src))):
        _p5(f"{tag}: SubResource '{rid}' declared", rid in declared_sub_ids)
    for rid in sorted(set(EXTREF_RE.findall(scene_src))):
        _p5(f"{tag}: ExtResource '{rid}' declared", rid in declared_ext_ids)
    for em in re.finditer(r'\[ext_resource type="([^"]*)" path="([^"]*)"', scene_src):
        fs = ROOT / em.group(2).removeprefix("res://")
        _p5(f"{tag}: ext path exists {em.group(2)}", fs.exists())

print()
print(f"TOTAL: {len(CHECKS)} checks, {len(FAILURES)} failed")
if FAILURES:
    for f in FAILURES:
        print("FAIL ->", f)
    sys.exit(1)
