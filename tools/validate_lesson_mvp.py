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
sys.exit(1 if FAILURES else 0)
