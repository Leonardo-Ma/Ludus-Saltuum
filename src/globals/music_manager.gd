## Coordinates music state with application state
extends Node


func _ready() -> void:
	ApplicationStateManager.state_changed.connect(_on_game_state_changed)
	GameplayStateManager.gameplay_mode_changed.connect(_on_gameplay_mode_changed)


func _on_game_state_changed(new_state: ApplicationStateManager.GameState, previous_state: ApplicationStateManager.GameState) -> void:
	match new_state:
		ApplicationStateManager.GameState.MAIN_MENU:
			SoundManager.change_music_state(MusicController.MusicState.MAIN_MENU, true)
		ApplicationStateManager.GameState.PLAYING:
			if previous_state == ApplicationStateManager.GameState.PAUSED:
				# Resume from pause, continue music
				pass
			else:
				SoundManager.change_music_state(MusicController.MusicState.EXPLORATION, true)
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
			SoundManager.change_music_state(MusicController.MusicState.RACING, true)
		GameplayStateManager.GameplayMode.COMBAT:
			SoundManager.change_music_state(MusicController.MusicState.COMBAT, true)
		GameplayStateManager.GameplayMode.MAZE:
			SoundManager.change_music_state(MusicController.MusicState.MAZE, true)
		GameplayStateManager.GameplayMode.NONE:
			if previous_mode != GameplayStateManager.GameplayMode.NONE:
				SoundManager.change_music_state(MusicController.MusicState.EXPLORATION, true)
