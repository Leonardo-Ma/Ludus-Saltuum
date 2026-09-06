## Gameplay state machine; Manages gameplay-specific modes like racing, maze, combat
## Works alongside ApplicationStateManager when in PLAYING state
## Emits signals for gameplay mode transitions
extends Node

signal gameplay_mode_changed(new_mode: GameplayMode, previous_mode: GameplayMode)
signal gameplay_mode_ended

enum GameplayMode {
	NONE = 0,
	RACING = 1,
	MAZE = 2,
	COMBAT = 3,
}

var _current_mode: GameplayMode = GameplayMode.NONE
var _previous_mode: GameplayMode = GameplayMode.NONE
var _is_initialized: bool = false

var _play_time_seconds: float = 0.0

@onready var _app_state_manager: ApplicationStateManager = ApplicationStateManager


func _ready() -> void:
	assert(not _is_initialized, "GameplayStateManager already initialized")
	_is_initialized = true

	_app_state_manager.state_changed.connect(_on_application_state_changed)

	if _app_state_manager.is_in_state(ApplicationStateManager.GameState.PLAYING):
		_on_application_state_entered_playing()

	SaveManager.reset_requested.connect(reset_save_data)


func _process(delta: float) -> void:
	_play_time_seconds += delta

#region Getters and Setters
func get_play_time() -> float:
	return _play_time_seconds


func set_play_time(seconds: float) -> void:
	_play_time_seconds = seconds

#endregion

func reset_save_data() -> void:
	set_play_time(0.0)


func _on_application_state_changed(new_state: ApplicationStateManager.GameState, _previous_state: ApplicationStateManager.GameState) -> void:
	match new_state:
		ApplicationStateManager.GameState.PLAYING:
			_on_application_state_entered_playing()
		ApplicationStateManager.GameState.PAUSED:
			_on_application_state_entered_paused()
		ApplicationStateManager.GameState.MAIN_MENU:
			_on_application_state_entered_main_menu()
		_:
			_change_mode(GameplayMode.NONE)


func _on_application_state_entered_playing() -> void:
	# When entering gameplay, we can restore previous gameplay mode or start with NONE
	pass


func _on_application_state_entered_paused() -> void:
	# Gameplay mode remains active but paused
	pass


func _on_application_state_entered_main_menu() -> void:
	# Ensure cleanup when returning to main menu
	_change_mode(GameplayMode.NONE)


func _change_mode(new_mode: GameplayMode) -> void:
	if _current_mode == new_mode:
		return

	_previous_mode = _current_mode
	_current_mode = new_mode

	_on_mode_entered(_current_mode, _previous_mode)
	gameplay_mode_changed.emit(_current_mode, _previous_mode)


func _on_mode_entered(new_mode: GameplayMode, previous_mode: GameplayMode) -> void:
	match new_mode:
		GameplayMode.NONE:
			if previous_mode != GameplayMode.NONE:
				gameplay_mode_ended.emit()


func get_current_mode() -> GameplayMode:
	return _current_mode


func get_previous_mode() -> GameplayMode:
	return _previous_mode


func is_in_mode(mode: GameplayMode) -> bool:
	return _current_mode == mode


func is_in_gameplay_mode() -> bool:
	return _current_mode != GameplayMode.NONE


func change_gameplay_state(new_mode: GameplayMode) -> void:
	if _app_state_manager.get_current_state() != ApplicationStateManager.GameState.PLAYING:
		push_error("Can only change gameplay mode during gameplay, current: " + str(_app_state_manager.get_current_state()))
	_change_mode(new_mode)
