# TODO Rename file to ui_view
## View controller UI scene root. Implements View of MVC
## Registers itself to UIManager
class_name UIView
extends CanvasLayer

@onready var _menus: MenusView = %Menus
@onready var _hud: Control = %HUD
@onready var _overlays: Control = %Overlays
@onready var _popups: Control = %Popups


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	UIManager.register_ui(self)

	for child: Control in get_children():
		assert(
			child.z_index != 0, child.name + " is missing CanvasItem > Ordering > Z Index. All children of UI must have manual screen ordering set"
		)


func show_main_menu() -> void:
	_menus.visible = true
	_menus.show_main_menu()
	_hud.visible = false
	_overlays.visible = false
	_popups.visible = false


func show_save_menu() -> void:
	_menus.visible = true
	_menus.show_save_menu()
	_hud.visible = false
	_overlays.visible = false
	_popups.visible = false


func show_game() -> void:
	_menus.visible = false
	_hud.visible = UIManager.hud_visible
	_overlays.visible = true
	_popups.visible = true


func show_pause_menu() -> void:
	_menus.visible = true
	_menus.show_pause_menu()
	_hud.visible = false
	_overlays.visible = false
	_popups.visible = false


func show_settings() -> void:
	_menus.visible = true
	_menus.show_settings()


func show_achievements() -> void:
	_menus.visible = true
	_menus.show_achievements()
	_hud.visible = false
	_overlays.visible = false
	_popups.visible = false


func show_main_menu_settings() -> void:
	_menus.visible = true
	_menus.show_main_menu_settings()
	_hud.visible = false
	_overlays.visible = false


func has_open_popup() -> bool:
	return _popups.has_open_popup()


func close_open_popup() -> void:
	_popups.close_open_popup()


func set_hud_visible(_hud_visible: bool) -> void:
	_hud.visible = _hud_visible
