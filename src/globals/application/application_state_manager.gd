## Application state machine; Coordinates UI, pause, menus, and quit
## Handles high-level application states, not gameplay-specific modes
## Root states (MAIN_MENU, PLAYING, PAUSED) via request_*, overlay menus stack on top via request_open_menu, pop via request_close_menu
## Emits signals for state transitions
extends Node

signal state_changed(new_state: GameState, previous_state: GameState)
signal main_menu_requested
signal gameplay_started
signal gameplay_paused
signal gameplay_resumed
signal menu_opened(menu: GameState)
signal menu_closed(menu: GameState)
signal main_menu_opened
signal quit_requested

enum GameState {
	MAIN_MENU = 0,
	PLAYING = 1,
	PAUSED = 2,
	SETTINGS = 3,
	SAVE_MENU = 4,
	ACHIEVEMENTS_MENU = 5,
	COSMETICS_MENU = 6,
}

## Overlay menu to states it can be opened from
## New menu = new enum value + new entry
const _MENU_ORIGINS: Dictionary[GameState, Array] = {
	GameState.SETTINGS: [GameState.MAIN_MENU, GameState.PAUSED],
	GameState.SAVE_MENU: [GameState.MAIN_MENU, GameState.PAUSED],
	GameState.ACHIEVEMENTS_MENU: [GameState.MAIN_MENU, GameState.PAUSED],
	GameState.COSMETICS_MENU: [GameState.PAUSED],
}

var _current_state: GameState = GameState.MAIN_MENU
var _previous_state: GameState = GameState.MAIN_MENU
## States below current overlay menu, last = return target
var _menu_stack: Array[GameState] = []

var _is_initialized: bool = false


func _ready() -> void:
	assert(not _is_initialized, "ApplicationStateManager already initialized")
	_is_initialized = true


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and not OS.is_debug_build():
		request_pause_if_playing()


func _apply_state(new_state: GameState) -> void:
	_previous_state = _current_state
	_current_state = new_state


func _change_root_state(new_state: GameState) -> void:
	_menu_stack.clear()
	_apply_state(new_state)
	_on_root_state_entered(new_state, _previous_state)
	state_changed.emit(new_state, _previous_state)


func _on_root_state_entered(new_state: GameState, previous_state: GameState) -> void:
	match new_state:
		GameState.MAIN_MENU:
			PauseManager.request_pause("gameplay")
			main_menu_opened.emit()

		GameState.PLAYING:
			PauseManager.release_pause("gameplay")
			if previous_state == GameState.PAUSED:
				gameplay_resumed.emit()
			else:
				gameplay_started.emit()

		GameState.PAUSED:
			PauseManager.request_pause("gameplay")
			gameplay_paused.emit()

		_:
			assert(false, "Not a root state: " + GameState.find_key(new_state))


func get_current_state() -> GameState:
	return _current_state


func get_previous_state() -> GameState:
	return _previous_state


func is_in_state(state: GameState) -> bool:
	return _current_state == state


func is_gameplay_active() -> bool:
	return _current_state in [GameState.PLAYING, GameState.PAUSED]


func is_in_overlay_menu() -> bool:
	return _MENU_ORIGINS.has(_current_state)


func is_in_menu() -> bool:
	return _current_state == GameState.MAIN_MENU or is_in_overlay_menu()


func is_in_settings() -> bool:
	return _current_state == GameState.SETTINGS


func is_paused() -> bool:
	return _current_state == GameState.PAUSED


func request_play_from_save() -> void:
	assert(
		_current_state in [GameState.SAVE_MENU, GameState.MAIN_MENU],
		"Can only start gameplay from SAVE_MENU or MAIN_MENU, current: " + GameState.find_key(_current_state),
	)
	_change_root_state(GameState.PLAYING)


func request_pause() -> void:
	assert(_current_state == GameState.PLAYING, "Can only pause from PLAYING, current: " + GameState.find_key(_current_state))
	_change_root_state(GameState.PAUSED)


func request_resume() -> void:
	assert(_current_state == GameState.PAUSED, "Can only resume from PAUSED, current: " + GameState.find_key(_current_state))
	_change_root_state(GameState.PLAYING)


func request_main_menu() -> void:
	assert(_current_state != GameState.MAIN_MENU, "Already in MAIN_MENU")
	main_menu_requested.emit()
	_change_root_state(GameState.MAIN_MENU)


func request_open_menu(menu: GameState) -> void:
	assert(_MENU_ORIGINS.has(menu), "Not an overlay menu: " + GameState.find_key(menu))
	assert(_current_state in _MENU_ORIGINS[menu], "Cannot open " + GameState.find_key(menu) + " from " + GameState.find_key(_current_state))
	_menu_stack.push_back(_current_state)
	_apply_state(menu)
	state_changed.emit(menu, _previous_state)
	menu_opened.emit(menu)


func request_close_menu() -> void:
	assert(is_in_overlay_menu(), "Not in an overlay menu, current: " + GameState.find_key(_current_state))
	var closed_menu: GameState = _current_state
	_apply_state(_menu_stack.pop_back())
	state_changed.emit(_current_state, _previous_state)
	menu_closed.emit(closed_menu)


func request_quit() -> void:
	quit_requested.emit()
	get_tree().quit()


func _on_settings_reset() -> void:
	if is_in_settings():
		SettingsManager.apply_all()


## Pauses only from PLAYING, safe for external triggers (focus loss, Steam overlay, gamepad disconnect)
func request_pause_if_playing() -> void:
	if _current_state == GameState.PLAYING:
		request_pause()
