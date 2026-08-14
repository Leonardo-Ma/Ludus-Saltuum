## View mediator; Shows/hides UI based on ApplicationStateManager signals
## Registers UIView and forwards ApplicationStateManager signals to it
## https://refactoring.guru/design-patterns/mediator
extends Node

signal hud_visibility_changed(visible: bool)

var hud_visible: bool = true

var _ui: UIView


func _ready() -> void:
	ApplicationStateManager.state_changed.connect(_on_game_state_changed)
	ApplicationStateManager.settings_opened.connect(_on_settings_opened)
	ApplicationStateManager.settings_closed.connect(_on_settings_closed)
	ApplicationStateManager.main_menu_opened.connect(_on_main_menu_opened)
	ApplicationStateManager.gameplay_started.connect(_on_gameplay_started)
	ApplicationStateManager.gameplay_resumed.connect(_on_gameplay_resumed)
	ApplicationStateManager.gameplay_paused.connect(_on_gameplay_paused)


func register_ui(ui: UIView) -> void:
	assert(_ui == null, "UIManager: UIView already registered")
	_ui = ui
	hud_visible = SettingsManager.hud_visible


func set_hud_visible(visible: bool) -> void:
	hud_visible = visible
	SettingsManager.hud_visible = visible
	SettingsManager.save()
	hud_visibility_changed.emit(visible)
	_get_ui().set_hud_visible(visible)


func show_main_menu() -> void:
	_get_ui().show_main_menu()


func show_gameplay() -> void:
	_get_ui().show_game()


func show_pause_menu() -> void:
	_get_ui().show_pause_menu()


func show_settings() -> void:
	_get_ui().show_settings()


func show_save_menu() -> void:
	_get_ui().show_save_menu()


func show_achievements() -> void:
	_get_ui().show_achievements()


func show_main_menu_settings() -> void:
	_get_ui().show_main_menu_settings()


func _on_game_state_changed(new_state: ApplicationStateManager.GameState, _previous_state: ApplicationStateManager.GameState) -> void:
	match new_state:
		ApplicationStateManager.GameState.MAIN_MENU:
			_ui.show_main_menu()
		ApplicationStateManager.GameState.PLAYING:
			_ui.show_game()
		ApplicationStateManager.GameState.PAUSED:
			_ui.show_pause_menu()
		ApplicationStateManager.GameState.SETTINGS:
			_ui.show_settings()
		ApplicationStateManager.GameState.SAVE_MENU:
			_ui.show_save_menu()
		ApplicationStateManager.GameState.ACHIEVEMENTS_MENU:
			_ui.show_achievements()
		ApplicationStateManager.GameState.MAIN_MENU_SETTINGS:
			_ui.show_main_menu_settings()


func _on_settings_opened() -> void:
	SettingsManager.apply_all()


func _on_settings_closed() -> void:
	pass


func _on_main_menu_opened() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _on_gameplay_started() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	print_debug("Mouse captured by UIManager")


# TODO Consider routing this to Input manager request release mouse? But would couple to that
# Maybe an autoload only for the signal instead? Or use pause manager?
func _on_gameplay_resumed() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


# TODO Consider routing this to Input manager request release mouse? But would couple to that
# Maybe an autoload only for the signal instead? Or use pause manager?
func _on_gameplay_paused() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _get_ui() -> UIView:
	assert(_ui != null, "UIManager: no UIView registered")
	return _ui
