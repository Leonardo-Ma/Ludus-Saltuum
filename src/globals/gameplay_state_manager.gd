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
var _suspended_mode: GameplayMode = GameplayMode.NONE
var _is_initialized: bool = false

var _play_time_seconds: float = 0.0


func _ready() -> void:
	assert(not _is_initialized, "GameplayStateManager already initialized")
	_is_initialized = true

	ApplicationStateManager.state_changed.connect(_on_application_state_changed)
	if ApplicationStateManager.is_in_state(ApplicationStateManager.GameState.PLAYING):
		_on_application_state_entered_playing()

	SaveManager.reset_requested.connect(reset_save_data)


func _process(delta: float) -> void:
	assert(ApplicationStateManager != null, "ApplicationStateManager missing in " + self.name)

	if ApplicationStateManager.is_gameplay_active():
		_play_time_seconds += delta

#region Getters and Setters
func get_play_time() -> float:
	return _play_time_seconds


func set_play_time(seconds: float) -> void:
	_play_time_seconds = seconds


func reset_save_data() -> void:
	set_play_time(0.0)


func get_current_mode() -> GameplayMode:
	return _current_mode


func get_previous_mode() -> GameplayMode:
	return _previous_mode


func is_in_mode(mode: GameplayMode) -> bool:
	return _current_mode == mode


func is_in_gameplay_mode() -> bool:
	return _current_mode != GameplayMode.NONE


func change_gameplay_state(new_mode: GameplayMode) -> void:
	assert(
		ApplicationStateManager.get_current_state() == ApplicationStateManager.GameState.PLAYING,
		"Can only change gameplay mode during gameplay, current: " + str(ApplicationStateManager.get_current_state()),
	)
	_change_mode(new_mode)
#endregion

#region Private helpers
func _on_application_state_changed(new_state: ApplicationStateManager.GameState, _previous_state: ApplicationStateManager.GameState) -> void:
	match new_state:
		ApplicationStateManager.GameState.PLAYING:
			_on_application_state_entered_playing()
		ApplicationStateManager.GameState.PAUSED:
			_on_application_state_entered_paused()
		ApplicationStateManager.GameState.MAIN_MENU:
			_on_application_state_entered_main_menu()
		ApplicationStateManager.GameState.SETTINGS:
			_on_application_state_entered_temporary_menu()
		ApplicationStateManager.GameState.SAVE_MENU:
			_on_application_state_entered_temporary_menu()
		ApplicationStateManager.GameState.ACHIEVEMENTS_MENU:
			_on_application_state_entered_temporary_menu()
		ApplicationStateManager.GameState.MAIN_MENU_SETTINGS:
			_on_application_state_entered_temporary_menu()


## Restores gameplay mode suspended by temporary application menus
func _on_application_state_entered_playing() -> void:
	_restore_suspended_mode()


## Restores gameplay mode suspended by temporary application menus
func _on_application_state_entered_paused() -> void:
	_restore_suspended_mode()


## Temporarily hides gameplay mode while preserving it for application-state return
func _on_application_state_entered_temporary_menu() -> void:
	if _current_mode == GameplayMode.NONE:
		return

	_suspended_mode = _current_mode
	_change_mode(GameplayMode.NONE)


## Clears gameplay state when returning to main menu
func _on_application_state_entered_main_menu() -> void:
	_suspended_mode = GameplayMode.NONE
	_change_mode(GameplayMode.NONE)


func _restore_suspended_mode() -> void:
	if _suspended_mode == GameplayMode.NONE:
		return

	var restored_mode: GameplayMode = _suspended_mode
	_suspended_mode = GameplayMode.NONE
	_change_mode(restored_mode)


func _change_mode(new_mode: GameplayMode) -> void:
	if _current_mode == new_mode:
		return

	_previous_mode = _current_mode
	_current_mode = new_mode

	_on_mode_entered(_current_mode, _previous_mode)
	gameplay_mode_changed.emit(_current_mode, _previous_mode)

	print_debug("Gameplay state changed to ", new_mode)


func _on_mode_entered(new_mode: GameplayMode, previous_mode: GameplayMode) -> void:
	match new_mode:
		GameplayMode.NONE:
			if previous_mode != GameplayMode.NONE:
				gameplay_mode_ended.emit()
#endregion
