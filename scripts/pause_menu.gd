extends CanvasLayer
class_name PauseMenu
## AngelTown pause menu: Resume, Performance Mode toggle, Return to Menu.
## Pauses the tree (world stops, this UI keeps working via WHEN_PAUSED).
## Performance Mode choice is persisted through TownSettings and applied
## via the `apply_performance` Callable provided by the world controller.

signal resume_requested
signal return_to_menu_requested

const MENU_SCENE := "res://scenes/ui_menu.tscn"

var _settings: TownSettings
## Callable(apply: bool) -> void: applies Performance Mode to the world.
var apply_performance := Callable()

@onready var _resume_btn: Button = $Root/Panel/Box/ResumeButton
@onready var _perf_btn: Button = $Root/Panel/Box/PerfButton
@onready var _menu_btn: Button = $Root/Panel/Box/MenuButton
@onready var _confirm: ConfirmationDialog = $ConfirmLeave


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	visible = false
	_settings = TownSettings.new()
	_settings.load_settings()
	_resume_btn.pressed.connect(_on_resume)
	_perf_btn.pressed.connect(_on_perf)
	_menu_btn.pressed.connect(_on_menu_requested)
	_confirm.confirmed.connect(_on_leave_confirmed)
	_refresh_perf_button()


func open() -> void:
	visible = true
	get_tree().paused = true


func close() -> void:
	visible = false
	get_tree().paused = false
	resume_requested.emit()


func is_open() -> bool:
	return visible


func _on_resume() -> void:
	close()


func _on_perf() -> void:
	GameSession.performance_mode = not GameSession.performance_mode
	_settings.performance_mode = GameSession.performance_mode
	_settings.save_settings()
	if apply_performance.is_valid():
		apply_performance.call(GameSession.performance_mode)
	_refresh_perf_button()


func _on_menu_requested() -> void:
	# Confirm before leaving the world (progress is saved automatically).
	_confirm.popup_centered()


func _on_leave_confirmed() -> void:
	get_tree().paused = false
	return_to_menu_requested.emit()
	get_tree().change_scene_to_file(MENU_SCENE)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST and is_open():
		close()  # back closes the pause menu first, like the overlay


func _unhandled_input(event: InputEvent) -> void:
	if is_open() and event.is_action_pressed("ui_cancel"):
		close()


func _refresh_perf_button() -> void:
	_perf_btn.text = "Performance Mode: ON" if GameSession.performance_mode \
		else "Performance Mode: OFF"
