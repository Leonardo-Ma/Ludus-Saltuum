## Shows MenuScreen child registered for current application state, hides the rest
class_name MenusView
extends Control

var _screens: Dictionary[ApplicationStateManager.GameState, MenuScreen] = { }


func _ready() -> void:
	for child: Node in get_children():
		var screen: MenuScreen = child as MenuScreen
		assert(screen != null, "Child is not a MenuScreen in " + name + ": " + child.name)
		assert(not _screens.has(screen.state), "Duplicate menu state in " + name + ": " + child.name)
		_screens[screen.state] = screen


func show_screen(state: ApplicationStateManager.GameState) -> void:
	for screen_state: ApplicationStateManager.GameState in _screens:
		_screens[screen_state].visible = screen_state == state
	visible = _screens.has(state)
