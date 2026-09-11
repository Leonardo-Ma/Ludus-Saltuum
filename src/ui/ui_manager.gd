## View mediator; Shows/hides UI based on ApplicationStateManager signals
## Registers UIView and forwards ApplicationStateManager signals to it
## https://refactoring.guru/design-patterns/mediator
extends Node

signal hud_visibility_changed(visible: bool)

var hud_visible: bool = true

var _ui: UIView

var _cancel_actions: Dictionary[ApplicationStateManager.GameState, Callable] = {
	ApplicationStateManager.GameState.SETTINGS: ApplicationStateManager.request_close_settings,
	ApplicationStateManager.GameState.MAIN_MENU_SETTINGS: ApplicationStateManager.request_close_settings,
	ApplicationStateManager.GameState.SAVE_MENU: ApplicationStateManager.request_close_menu,
	ApplicationStateManager.GameState.ACHIEVEMENTS_MENU: ApplicationStateManager.request_close_menu,
}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func register_ui(ui: UIView) -> void:
	assert(_ui == null, "UIManager: UIView already registered")
	_ui = ui
	hud_visible = SettingsManager.hud_visible

	ApplicationStateManager.state_changed.connect(_on_game_state_changed)
	ApplicationStateManager.settings_opened.connect(_on_settings_opened)
	ApplicationStateManager.settings_closed.connect(_on_settings_closed)


# BUG Web version: ESC releases mouse and ignores this on first press but works on second ESC press.
func _unhandled_input(event: InputEvent) -> void:
	var current_state: ApplicationStateManager.GameState = ApplicationStateManager.get_current_state()
	if current_state == ApplicationStateManager.GameState.MAIN_MENU:
		return

	if event.is_action_pressed("toggle_hud"):
		set_hud_visible(not hud_visible)
		_ui.get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("ui_cancel"):
		if _ui.has_open_popup():
			_ui.close_open_popup()
			_ui.get_viewport().set_input_as_handled()
			return

		var action: Callable = _cancel_actions.get(current_state, Callable())
		if action.is_valid():
			action.call()
			_ui.get_viewport().set_input_as_handled()

	if event.is_action_pressed("pause"):
		match current_state:
			ApplicationStateManager.GameState.PLAYING:
				ApplicationStateManager.request_pause()
			ApplicationStateManager.GameState.PAUSED:
				ApplicationStateManager.request_resume()
			_:
				return

		_ui.get_viewport().set_input_as_handled()
		return


func set_hud_visible(visible: bool) -> void:
	hud_visible = visible
	SettingsManager.hud_visible = visible
	SettingsManager.save()
	hud_visibility_changed.emit(visible)
	_ui.set_hud_visible(visible)


# TODO Check how the unused argument could be omitted without possible silent fails
@warning_ignore("unused_parameter") # gdlint-ignore-next-line unused-argument
func _on_game_state_changed(new_state: ApplicationStateManager.GameState, previous_state: ApplicationStateManager.GameState) -> void:
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

	if new_state == ApplicationStateManager.GameState.PLAYING:
		MouseModeManager.release(&"menu")
		MouseModeManager.request_mode(&"gameplay", Input.MOUSE_MODE_CAPTURED)
	else:
		MouseModeManager.release(&"gameplay")
		MouseModeManager.release(&"menu")


func _on_settings_opened() -> void:
	pass


func _on_settings_closed() -> void:
	pass
