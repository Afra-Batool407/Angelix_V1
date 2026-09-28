extends Node3D
## AngelTown world controller: spawns the student, runs the Angel companion,
## manages learning stations, and opens/closes the lesson overlay WITHOUT
## replacing the world scene (player, Angel, position and state are kept).
##
## All learning content is keyed by stable topic IDs via GameSession. Stations
## are configuration (LearningStation exports); only topics with a validated
## content JSON can open a lesson. Locked stations never open fabricated
## content.

const MENU_SCENE := "res://scenes/ui_menu.tscn"
const LESSON_SCENE := "res://scenes/lesson.tscn"
const PLAYER_SCENE := "res://scenes/player.tscn"
const HUB_SPAWN := Vector3(0, 6, 8)
const DEFAULT_STATION_POS := Vector3(8, 6, 2)

const LESSON_OVERLAY_GROUP := "lesson_overlay"

@onready var _angel: CharacterBody3D = $Angel
@onready var _camera_rig: Node3D = $CameraRig
@onready var _hud: CanvasLayer = $HUD
@onready var _interact_button: Button = $HUD/InteractButton
@onready var _prompt_label: Label = $HUD/PromptLabel
@onready var _menu_button: Button = $HUD/MenuButton
@onready var _overlay_root: Control = $LessonOverlay/Root
@onready var _overlay_holder: Control = $LessonOverlay/Root/Panel/Holder
@onready var _overlay_close: Button = $LessonOverlay/Root/Panel/TopBar/CloseButton

var _player: PlayerController
var _stations: Array = []
var _active_station: LearningStation = null
var _lesson_open := false
var _lesson_instance: Control = null


func _ready() -> void:
	_setup_stations()
	_spawn_player()
	_setup_companion()
	_setup_overlay()
	_setup_hud()
	_apply_topic_selection()


# ----------------------------------------------------------------- spawn

func _spawn_player() -> void:
	var scene: PackedScene = load(PLAYER_SCENE)
	_player = scene.instantiate() as PlayerController
	_player.add_to_group("player")
	_player.global_position = _resolve_spawn_position()
	add_child(_player)

	# Camera follows the student now; Angel follows the student.
	_camera_rig.set_target(_player)


func _resolve_spawn_position() -> Vector3:
	var selected := GameSession.selected_topic_id
	if selected == "" or not GameSession.has_topic_content(selected):
		return HUB_SPAWN
	for st in _stations:
		if st is LearningStation and GameSession.matches_station(selected, st.topic_id):
			return (st as LearningStation).global_position + Vector3(0, 2.5, 4.0)
	return HUB_SPAWN


# ------------------------------------------------------------- companion

func _setup_companion() -> void:
	# Angel is a CharacterBody3D with its own hover physics; point its target
	# at the player through a small companion driver so it glides after the
	# student without any navigation dependency.
	var driver := AngelFollower.new()
	add_child(driver)
	driver.configure(_angel, _player)


# ---------------------------------------------------------------- stations

func _setup_stations() -> void:
	_stations = []
	for node in get_tree().get_nodes_in_group("learning_station"):
		if node is LearningStation:
			_stations.append(node)
	if _stations.is_empty():
		# Fallback: create the Real Numbers station in code if the scene
		# lacks it (keeps the world playable even if the scene is edited).
		var st := LearningStation.new()
		st.topic_id = "math.u01.real-numbers"
		st.display_title = "1.1 Introduction to Real Numbers"
		st.position = DEFAULT_STATION_POS
		add_child(st)
		_stations.append(st)
	for st in _stations:
		(st as LearningStation).player_entered.connect(_on_station_entered)
		(st as LearningStation).player_exited.connect(_on_station_exited)


func _on_station_entered(station: LearningStation) -> void:
	_active_station = station
	station.set_ring_active(true)
	_refresh_prompt()


func _on_station_exited(station: LearningStation) -> void:
	station.set_ring_active(false)
	if _active_station == station:
		_active_station = null
	_refresh_prompt()


func _refresh_prompt() -> void:
	if _active_station == null or _lesson_open:
		_prompt_label.visible = false
		_interact_button.visible = false
		return
	_prompt_label.text = _active_station.display_title \
		+ ("  (Coming soon)" if not _active_station.available else "")
	_prompt_label.visible = true
	# Interact only for stations that actually have content.
	_interact_button.visible = _active_station.available \
		and GameSession.has_topic_content(_active_station.topic_id)


# ---------------------------------------------------------------- overlay

func _setup_overlay() -> void:
	_overlay_root.visible = false
	_overlay_close.pressed.connect(_close_lesson)


func _open_lesson(topic_id: String) -> void:
	if _lesson_open or not GameSession.has_topic_content(topic_id):
		return
	var packed: PackedScene = load(LESSON_SCENE)
	_lesson_instance = packed.instantiate() as Control
	if topic_id != "math.u01.real-numbers":
		# Future topics: lesson reads the station's own content file.
		_lesson_instance.set("topic_path_override", GameSession.content_path_for(topic_id))
	_lesson_instance.add_to_group(LESSON_OVERLAY_GROUP)
	_overlay_holder.add_child(_lesson_instance)
	_lesson_open = true
	_overlay_root.visible = true
	if _player != null:
		_player.locked = true
	_refresh_prompt()


func _close_lesson() -> void:
	if not _lesson_open:
		return
	_overlay_root.visible = false
	if is_instance_valid(_lesson_instance):
		_lesson_instance.queue_free()
	_lesson_instance = null
	_lesson_open = false
	if _player != null:
		_player.locked = false
	_refresh_prompt()


func is_lesson_open() -> bool:
	return _lesson_open


# ------------------------------------------------------------------- hud

func _setup_hud() -> void:
	_menu_button.pressed.connect(_confirm_return_to_menu)
	_interact_button.pressed.connect(_on_interact_pressed)
	_refresh_prompt()


func _on_interact_pressed() -> void:
	if _active_station != null and not _lesson_open:
		_open_lesson(_active_station.topic_id)


func _confirm_return_to_menu() -> void:
	# Minimal safe confirmation dialog (ConfirmationDialog is touch-unfriendly
	# on some Android builds, so use a small custom panel if needed later).
	var dialog := ConfirmationDialog.new()
	dialog.dialog_text = "Return to the menu? Your position and progress are saved."
	get_tree().root.add_child(dialog)
	dialog.confirmed.connect(_go_to_menu)
	dialog.cancelled.connect(dialog.queue_free)
	dialog.popup_centered()


func _go_to_menu() -> void:
	get_tree().change_scene_to_file(MENU_SCENE)


# ------------------------------------------------------------ input flow

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if _lesson_open:
			_close_lesson()
		else:
			_confirm_return_to_menu()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if _lesson_open:
			_close_lesson()
		else:
			_confirm_return_to_menu()


class AngelFollower:
	extends Node
	## Glides the Angel smoothly after the player with a safe offset, using
	## the Angel's own hover physics. No navigation dependency; if the Angel
	## falls too far behind, it catches up with a higher glide speed and a
	## graceful teleport as a last resort (never traps the player).
	const OFFSET := Vector3(1.6, 2.2, 2.6)
	const FOLLOW_SPEED := 6.5
	const CATCHUP_SPEED := 11.0
	const CATCHUP_DIST := 14.0
	const TELEPORT_DIST := 26.0

	var _angel: CharacterBody3D
	var _player: PlayerController

	func get_path_placeholder() -> NodePath:
		return NodePath("")

	func configure(angel: CharacterBody3D, player: PlayerController) -> void:
		_angel = angel
		_player = player

	func _physics_process(delta: float) -> void:
		if _angel == null or _player == null:
			return
		if not is_instance_valid(_angel) or not is_instance_valid(_player):
			return
		var goal := _player.global_position + OFFSET
		var to_goal := goal - _angel.global_position
		var dist := to_goal.length()
		if dist > TELEPORT_DIST:
			_angel.global_position = goal + Vector3(0, 2.0, 0)
			return
		var speed := FOLLOW_SPEED if dist < CATCHUP_DIST else CATCHUP_SPEED
		var dir := to_goal / max(dist, 0.001)
		# Push the Angel's velocity horizontally; its own hover physics
		# (angel.gd) keeps it at the right height with a gentle bob.
		_angel.velocity.x = dir.x * speed
		_angel.velocity.z = dir.z * speed
		_angel.velocity.y = dir.y * speed * 0.8 + 0.5
