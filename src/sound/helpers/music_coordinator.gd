extends Node

## Coordinates music state with application state

var _refresh_queued: bool = false


func _ready() -> void:
	ApplicationStateManager.state_changed.connect(_on_game_state_changed)
	GameplayStateManager.gameplay_mode_changed.connect(_on_gameplay_mode_changed)
	_refresh()


func _on_game_state_changed(_new_state: ApplicationStateManager.GameState, _previous_state: ApplicationStateManager.GameState) -> void:
	_queue_refresh()


func _on_gameplay_mode_changed(_new_mode: GameplayStateManager.GameplayMode, _previous_mode: GameplayStateManager.GameplayMode) -> void:
	_queue_refresh()


func _queue_refresh() -> void:
	if _refresh_queued:
		return

	_refresh_queued = true
	_refresh.call_deferred()


func _refresh() -> void:
	_refresh_queued = false

	if ApplicationStateManager.is_in_overlay_menu():
		return

	MusicController.set_state(_resolve_state())


func _resolve_state() -> MusicController.MusicState:
	if ApplicationStateManager.is_in_state(ApplicationStateManager.GameState.MAIN_MENU):
		return MusicController.MusicState.MAIN_MENU

	match GameplayStateManager.get_current_mode():
		GameplayStateManager.GameplayMode.RACING:
			return MusicController.MusicState.RACING
		GameplayStateManager.GameplayMode.COMBAT:
			return MusicController.MusicState.COMBAT
		GameplayStateManager.GameplayMode.MAZE:
			return MusicController.MusicState.MAZE
		GameplayStateManager.GameplayMode.OUTER_SPACE:
			return MusicController.MusicState.OUTER_SPACE
		GameplayStateManager.GameplayMode.NONE:
			return MusicController.MusicState.EXPLORATION

	assert(false, "Unsupported gameplay mode in " + name)
	return MusicController.MusicState.EXPLORATION
