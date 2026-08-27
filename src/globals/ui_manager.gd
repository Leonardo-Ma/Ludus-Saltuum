## View mediator; Shows/hides UI based on ApplicationStateManager signals
## Registers UIView and forwards ApplicationStateManager signals to it
## https://refactoring.guru/design-patterns/mediator
extends Node

signal hud_visibility_changed(visible: bool)

var hud_visible: bool = true

var _ui: UIView


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	ApplicationStateManager.state_changed.connect(_on_game_state_changed)
	ApplicationStateManager.settings_opened.connect(_on_settings_opened)
	ApplicationStateManager.settings_closed.connect(_on_settings_closed)


func register_ui(ui: UIView) -> void:
	assert(_ui == null, "UIManager: UIView already registered")
	_ui = ui
	hud_visible = SettingsManager.hud_visible


# TODO Improve this garbage, should be _gui_input but doesn't work if so
# BUG Web version: ESC releases mouse and ignores this on first press but works on second ESC press.
# gdlint: disable=max-returns
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_hud"):
		set_hud_visible(not hud_visible)
		_get_ui().get_viewport().set_input_as_handled()
		return

	# TODO This shouldn't be here
	if event.is_action_pressed("quick_save") and ApplicationStateManager.is_gameplay_active():
		SaveManager.save_to_quick_slot()
		_get_ui().get_viewport().set_input_as_handled()
		return

	if not event.is_action_pressed("ui_cancel"):
		return

	if _get_ui().has_open_popup():
		_get_ui().close_open_popup()
		_get_ui().get_viewport().set_input_as_handled()
		return

	if ApplicationStateManager.is_in_state(ApplicationStateManager.GameState.MAIN_MENU):
		return
	if ApplicationStateManager.is_in_settings():
		ApplicationStateManager.request_close_settings()
		_get_ui().get_viewport().set_input_as_handled()
		return
	if (
		ApplicationStateManager.is_in_state(ApplicationStateManager.GameState.SAVE_MENU)
		or ApplicationStateManager.is_in_state(ApplicationStateManager.GameState.ACHIEVEMENTS_MENU)
		or ApplicationStateManager.is_in_state(ApplicationStateManager.GameState.MAIN_MENU_SETTINGS)
	):
		ApplicationStateManager.request_close_menu()
		_get_ui().get_viewport().set_input_as_handled()
		return
	if not ApplicationStateManager.is_paused():
		ApplicationStateManager.request_pause()
	else:
		ApplicationStateManager.request_resume()
	_get_ui().get_viewport().set_input_as_handled()


func set_hud_visible(visible: bool) -> void:
	hud_visible = visible
	SettingsManager.hud_visible = visible
	SettingsManager.save()
	hud_visibility_changed.emit(visible)
	_get_ui().set_hud_visible(visible)


# TODO Check how the unused argument could be omitted without possible silent fails
@warning_ignore("unused_parameter")  # gdlint:ignore=unused-argument
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
		MouseModeManager.request_mode(&"menu", Input.MOUSE_MODE_VISIBLE)


func _on_settings_opened() -> void:
	pass


func _on_settings_closed() -> void:
	pass


func _get_ui() -> UIView:
	assert(_ui != null, "UIManager: no UIView registered")
	return _ui
