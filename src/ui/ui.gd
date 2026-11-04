# TODO Rename file to ui_view
## View controller UI scene root. Implements View of MVC
## Registers itself to UIManager
class_name UIView
extends CanvasLayer

@onready var _menus: MenusView = %Menus
@onready var _hud: Control = %HUD
@onready var _overlays: Control = %Overlays
@onready var _popups: PopupsManager = %Popups


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	UIManager.register_ui(self)

	for child: Control in get_children():
		assert(
			child.z_index != 0,
			child.name + " is missing CanvasItem > Ordering > Z Index. All children of UI must have manual screen ordering set",
		)

	present(ApplicationStateManager.get_current_state())


## Menus show screen registered for state, HUD / overlays / popups only while playing
## Open popups are closed by PopupsManager on state change
func present(state: ApplicationStateManager.GameState) -> void:
	var is_playing: bool = state == ApplicationStateManager.GameState.PLAYING
	_menus.show_screen(state)
	_hud.visible = is_playing and UIManager.hud_visible
	_overlays.visible = is_playing
	_popups.visible = is_playing


func has_open_popup() -> bool:
	return _popups.has_open_popup()


func close_open_popup() -> void:
	_popups.close_open_popup()


func request_confirmation(icons: Array[CompressedTexture2D]) -> bool:
	if not _popups.open_confirmation(icons):
		return false

	var confirmed: bool = await _popups.confirmation_popup.choice_made
	return confirmed


func set_hud_visible(_hud_visible: bool) -> void:
	_hud.visible = _hud_visible and ApplicationStateManager.is_in_state(ApplicationStateManager.GameState.PLAYING)
