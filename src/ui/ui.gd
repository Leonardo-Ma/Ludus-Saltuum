# TODO Rename file to ui_view
## View controller UI scene root. Implements View of MVC
## Registers itself to UIManager
class_name UIView
extends CanvasLayer

signal confirmation_finished(confirmed: bool)

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


func show_main_menu() -> void:
	_popups.close_all_popups()
	_menus.show()
	_menus.show_main_menu()
	_hud.hide()
	_overlays.hide()
	_popups.hide()


func show_save_menu() -> void:
	_popups.close_all_popups()
	_menus.show()
	_menus.show_save_menu()
	_hud.hide()
	_overlays.hide()
	_popups.hide()


func show_game() -> void:
	_menus.hide()
	_hud.visible = UIManager.hud_visible
	_overlays.show()
	_popups.show()


func show_pause_menu() -> void:
	_popups.close_all_popups()
	_menus.show()
	_menus.show_pause_menu()
	_hud.hide()
	_overlays.hide()
	_popups.hide()


func show_settings() -> void:
	_menus.show()
	_menus.show_settings()


func show_achievements() -> void:
	_popups.close_all_popups()
	_menus.show()
	_menus.show_achievements()
	_hud.hide()
	_overlays.hide()
	_popups.hide()


func show_main_menu_settings() -> void:
	_menus.show()
	_menus.show_main_menu_settings()
	_hud.hide()
	_overlays.hide()


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
