## Coordinates music state with application state
extends Node


func _ready() -> void:
	ApplicationStateManager.state_changed.connect(_on_game_state_changed)
	GameplayStateManager.gameplay_mode_changed.connect(_on_gameplay_mode_changed)
	_synchronize_current_game_state()


func _on_game_state_changed(new_state: ApplicationStateManager.GameState, previous_state: ApplicationStateManager.GameState) -> void:
	match new_state:
		ApplicationStateManager.GameState.MAIN_MENU:
			MusicController.set_state(MusicController.MusicState.MAIN_MENU)
		ApplicationStateManager.GameState.PLAYING:
			if previous_state == ApplicationStateManager.GameState.PAUSED:
				# Resume from pause, continue music
				pass
			else:
				MusicController.set_state(MusicController.MusicState.EXPLORATION)
		ApplicationStateManager.GameState.PAUSED:
			# Keep music playing but could lower volume if desired
			pass
		ApplicationStateManager.GameState.SETTINGS:
			pass
		ApplicationStateManager.GameState.SAVE_MENU:
			pass
		ApplicationStateManager.GameState.ACHIEVEMENTS_MENU:
			pass
		ApplicationStateManager.GameState.MAIN_MENU_SETTINGS:
			pass


func _on_gameplay_mode_changed(new_mode: GameplayStateManager.GameplayMode, previous_mode: GameplayStateManager.GameplayMode) -> void:
	match new_mode:
		GameplayStateManager.GameplayMode.RACING:
			MusicController.set_state(MusicController.MusicState.RACING)
		GameplayStateManager.GameplayMode.COMBAT:
			MusicController.set_state(MusicController.MusicState.COMBAT)
		GameplayStateManager.GameplayMode.MAZE:
			MusicController.set_state(MusicController.MusicState.MAZE)
		GameplayStateManager.GameplayMode.NONE:
			if previous_mode != GameplayStateManager.GameplayMode.NONE:
				MusicController.set_state(MusicController.MusicState.EXPLORATION)


func _synchronize_current_game_state() -> void:
	match ApplicationStateManager.get_current_state():
		ApplicationStateManager.GameState.MAIN_MENU:
			MusicController.set_state(MusicController.MusicState.MAIN_MENU)
		ApplicationStateManager.GameState.PLAYING:
			MusicController.set_state(MusicController.MusicState.EXPLORATION)
		ApplicationStateManager.GameState.PAUSED:
			MusicController.set_state(MusicController.MusicState.EXPLORATION)
		ApplicationStateManager.GameState.SETTINGS:
			pass
		ApplicationStateManager.GameState.SAVE_MENU:
			pass
		ApplicationStateManager.GameState.ACHIEVEMENTS_MENU:
			pass
		ApplicationStateManager.GameState.MAIN_MENU_SETTINGS:
			pass
