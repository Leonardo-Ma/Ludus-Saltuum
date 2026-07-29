## Game/Application state machine; Coordinates UI, pause, settings, main menu, quit
## Emits signals for state transitions
extends Node

signal state_changed(new_state: GameState, previous_state: GameState)
signal main_menu_requested
signal gameplay_started
signal gameplay_paused
signal gameplay_resumed
signal settings_opened
signal settings_closed
signal main_menu_opened
signal quit_requested

enum GameState {
	MAIN_MENU,
	PLAYING,
	PAUSED,
	SETTINGS,
	SAVE_MENU,
	ACHIEVEMENTS_MENU,
	MAIN_MENU_SETTINGS,
}

var _current_state: GameState = GameState.MAIN_MENU
var _previous_state: GameState = GameState.MAIN_MENU
var _is_initialized: bool = false


func _ready() -> void:
	assert(not _is_initialized, "GameStateManager already initialized")
	_is_initialized = true


func _change_state(new_state: GameState) -> void:
	if _current_state == new_state:
		return
	assert(_is_valid_transition(_current_state, new_state), "Invalid state transition from " + str(_current_state) + " to " + str(new_state))

	_previous_state = _current_state
	_current_state = new_state

	_on_state_entered(_current_state, _previous_state)
	state_changed.emit(_current_state, _previous_state)


# gdlint: disable=max-returns
func _is_valid_transition(from_state: GameState, to_state: GameState) -> bool:
	match from_state:
		GameState.MAIN_MENU:
			return to_state in [GameState.PLAYING, GameState.MAIN_MENU_SETTINGS, GameState.SAVE_MENU, GameState.ACHIEVEMENTS_MENU]
		GameState.PLAYING:
			return to_state in [GameState.PAUSED, GameState.MAIN_MENU, GameState.SETTINGS]
		GameState.PAUSED:
			return to_state in [GameState.PLAYING, GameState.MAIN_MENU, GameState.SETTINGS, GameState.SAVE_MENU, GameState.ACHIEVEMENTS_MENU]
		GameState.SETTINGS:
			return to_state in [GameState.PLAYING, GameState.PAUSED, GameState.MAIN_MENU, GameState.MAIN_MENU_SETTINGS]
		GameState.SAVE_MENU:
			return to_state in [GameState.PLAYING, GameState.PAUSED, GameState.MAIN_MENU]
		GameState.ACHIEVEMENTS_MENU:
			return to_state in [GameState.PAUSED, GameState.MAIN_MENU]
		GameState.MAIN_MENU_SETTINGS:
			return to_state in [GameState.MAIN_MENU, GameState.SETTINGS]
		_:
			return false


func _on_state_entered(new_state: GameState, previous_state: GameState) -> void:
	match new_state:
		GameState.MAIN_MENU:
			UIManager.show_main_menu()
			PauseManager.request_pause("gameplay")
			main_menu_opened.emit()

		GameState.PLAYING:
			UIManager.show_gameplay()
			PauseManager.release_pause("gameplay")
			gameplay_started.emit()
			if previous_state == GameState.PAUSED:
				gameplay_resumed.emit()

		GameState.PAUSED:
			UIManager.show_pause_menu()
			PauseManager.request_pause("gameplay")
			gameplay_paused.emit()

		GameState.SETTINGS:
			UIManager.show_settings()
			SettingsManager.apply_all()
			settings_opened.emit()

		GameState.SAVE_MENU:
			UIManager.show_save_menu()

		GameState.ACHIEVEMENTS_MENU:
			UIManager.show_achievements()

		GameState.MAIN_MENU_SETTINGS:
			UIManager.show_main_menu_settings()
			SettingsManager.apply_all()
			settings_opened.emit()


func get_current_state() -> GameState:
	return _current_state


func get_previous_state() -> GameState:
	return _previous_state


func is_in_state(state: GameState) -> bool:
	return _current_state == state


func is_gameplay_active() -> bool:
	return _current_state in [GameState.PLAYING, GameState.PAUSED]


func is_in_menu() -> bool:
	return _current_state in [GameState.MAIN_MENU, GameState.SETTINGS, GameState.SAVE_MENU, GameState.ACHIEVEMENTS_MENU, GameState.MAIN_MENU_SETTINGS]


func is_in_settings() -> bool:
	return _current_state in [GameState.SETTINGS, GameState.MAIN_MENU_SETTINGS]


func is_paused() -> bool:
	return _current_state == GameState.PAUSED


func request_new_game() -> void:
	assert(_current_state == GameState.MAIN_MENU, "Can only start new game from MAIN_MENU, current: " + str(_current_state))
	_change_state(GameState.SAVE_MENU)


func request_play_from_save() -> void:
	assert(_current_state == GameState.SAVE_MENU, "Can only start gameplay from SAVE_MENU, current: " + str(_current_state))
	_change_state(GameState.PLAYING)


func request_pause() -> void:
	assert(_current_state == GameState.PLAYING, "Can only pause from PLAYING, current: " + str(_current_state))
	_change_state(GameState.PAUSED)


func request_resume() -> void:
	assert(_current_state == GameState.PAUSED, "Can only resume from PAUSED, current: " + str(_current_state))
	_change_state(GameState.PLAYING)


func request_settings() -> void:
	assert(
		_current_state in [GameState.PLAYING, GameState.PAUSED, GameState.MAIN_MENU, GameState.MAIN_MENU_SETTINGS],
		"Can only open settings from gameplay or main menu, current: " + str(_current_state)
	)

	if _current_state == GameState.MAIN_MENU:
		_change_state(GameState.MAIN_MENU_SETTINGS)
	elif _current_state == GameState.MAIN_MENU_SETTINGS:
		_change_state(GameState.SETTINGS)
	else:
		_change_state(GameState.SETTINGS)


func request_close_settings() -> void:
	assert(is_in_settings(), "Not in settings state, current: " + str(_current_state))

	if _current_state == GameState.SETTINGS:
		if _previous_state in [GameState.PLAYING, GameState.PAUSED]:
			_change_state(_previous_state)
		else:
			_change_state(GameState.PAUSED)
	elif _current_state == GameState.MAIN_MENU_SETTINGS:
		_change_state(GameState.MAIN_MENU)
	settings_closed.emit()


func request_close_menu() -> void:
	assert(
		_current_state in [GameState.SETTINGS, GameState.SAVE_MENU, GameState.ACHIEVEMENTS_MENU, GameState.MAIN_MENU_SETTINGS],
		"Not in a closable menu state, current: " + str(_current_state)
	)
	_change_state(_previous_state)


func request_main_menu() -> void:
	assert(_current_state != GameState.MAIN_MENU, "Already in MAIN_MENU")
	main_menu_requested.emit()
	_change_state(GameState.MAIN_MENU)


func request_save_menu() -> void:
	assert(
		_current_state in [GameState.MAIN_MENU, GameState.PAUSED], "Can only open save menu from MAIN_MENU or PAUSED, current: " + str(_current_state)
	)
	_change_state(GameState.SAVE_MENU)


func request_achievements_menu() -> void:
	assert(
		_current_state in [GameState.MAIN_MENU, GameState.PAUSED],
		"Can only open achievements from MAIN_MENU or PAUSED, current: " + str(_current_state)
	)
	_change_state(GameState.ACHIEVEMENTS_MENU)


func request_quit() -> void:
	quit_requested.emit()
	get_tree().quit()


func _on_settings_reset() -> void:
	if is_in_settings():
		SettingsManager.apply_all()
