## Shows MenuScreen child registered for current application state, hides the rest
class_name MenusView
extends Control

var _screens: Dictionary[ApplicationStateManager.GameState, MenuScreen] = { }

@onready var _pause_menu: PauseMenuView = %PauseMenu
@onready var _cosmetics_menu: CosmeticsMenuView = %CosmeticsMenu


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


## Assigns player data to menus with account-specific controls
func bind_player_features(economy: EconomyController, cosmetics: CosmeticsController) -> void:
	_pause_menu.bind_cosmetics(cosmetics)
	_cosmetics_menu.bind_player_features(economy, cosmetics)
