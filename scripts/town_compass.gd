extends Control
class_name TownCompass
## Lightweight compass pointing to the nearest available (incomplete)
## station. Pure CanvasItem drawing - no minimap, no render targets, no
## per-pixel cost. The world controller calls update_compass() a few times
## per second with cheap math only.

var player_position := Vector3.ZERO
var player_yaw := 0.0
var targets: Array = []          ## [{ "pos": Vector3, "label": String }]
var _needle_target := Vector2.ZERO
var _target_label := ""

func _draw() -> void:
	var c := size * 0.5
	var r := minf(c.x, c.y) - 4.0
	# Dial
	draw_circle(c, r, Color(0.05, 0.07, 0.13, 0.75))
	draw_arc(c, r, 0, TAU, 40, Color(0.6, 0.68, 0.9, 0.9), 2.0, true)
	# North marker (world -Z). Screen-up is camera-forward, so north sits at
	# angle -(player_yaw) from up.
	var north := Vector2.UP.rotated(-player_yaw)
	draw_line(c, c + north * (r * 0.45), c + north * (r * 0.85), Color(0.95, 0.4, 0.4), 3.0)
	draw_string(ThemeDB.fallback_font, c + north * r * 0.6 + Vector2(-4, -8), "N",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.95, 0.5, 0.5))
	# Nearest-target needle
	if _needle_target != Vector2.ZERO:
		draw_line(c, c + _needle_target * (r * 0.8), Color(0.98, 0.72, 0.25), 4.0)
		draw_circle(c + _needle_target * (r * 0.8), 4.0, Color(0.98, 0.72, 0.25))


func update_compass(player_pos: Vector3, yaw: float, new_targets: Array) -> void:
	player_position = player_pos
	player_yaw = yaw
	targets = new_targets
	_pick_nearest()
	queue_redraw()


func _pick_nearest() -> void:
	# Prefer available (incomplete) stations; locked ones only appear when
	# nothing else is pending.
	var best_d := INF
	var best_dir := Vector2.ZERO
	_target_label = ""
	var best_available := false
	for t in targets:
		if not (t is Dictionary) or not t.has("pos"):
			continue
		var pos: Vector3 = t["pos"]
		var available := bool(t.get("available", false))
		if best_available and not available:
			continue
		var to := pos - player_position
		var d := Vector2(to.x, to.z).length()
		if d < best_d or (available and not best_available):
			best_d = d
			best_available = available
			_target_label = String(t.get("label", ""))
			# Rotate world direction into camera space (yaw only).
			var world_dir := Vector2(to.x, to.z).normalized()
			best_dir = world_dir.rotated(-player_yaw - PI)
	_needle_target = best_dir
