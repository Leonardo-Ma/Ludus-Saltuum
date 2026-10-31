# TODO Change this to be signal based and uncouple from other menus
class_name MenusView
extends Control

## Controls menus visibility

@onready var _main_menu: Control = %MainMenu
@onready var _pause_menu: Control = %PauseMenu
@onready var _settings_menu: Control = %SettingsMenu
@onready var _save_menu: Control = %SaveMenu
@onready var _achievements_menu: Control = %AchievementsMenu
@onready var _cosmetics_menu: Control = %CosmeticsMenu


func show_main_menu() -> void:
	_main_menu.show()
	_pause_menu.hide()
	_settings_menu.hide()
	_save_menu.hide()
	_achievements_menu.hide()
	_cosmetics_menu.hide()


func show_save_menu() -> void:
	_main_menu.hide()
	_pause_menu.hide()
	_settings_menu.hide()
	_save_menu.show()
	_achievements_menu.hide()
	_cosmetics_menu.hide()


func show_pause_menu() -> void:
	_main_menu.hide()
	_pause_menu.show()
	_settings_menu.hide()
	_save_menu.hide()
	_achievements_menu.hide()
	_cosmetics_menu.hide()


func show_settings() -> void:
	_main_menu.hide()
	_pause_menu.hide()
	_settings_menu.show()
	_save_menu.hide()
	_achievements_menu.hide()
	_cosmetics_menu.hide()


func show_achievements() -> void:
	_main_menu.hide()
	_pause_menu.hide()
	_settings_menu.hide()
	_save_menu.hide()
	_achievements_menu.show()
	_cosmetics_menu.hide()


func show_main_menu_settings() -> void:
	_main_menu.hide()
	_pause_menu.hide()
	_settings_menu.show()
	_save_menu.hide()
	_achievements_menu.hide()
	_cosmetics_menu.hide()


func show_cosmetics_menu() -> void:
	_main_menu.hide()
	_pause_menu.hide()
	_settings_menu.hide()
	_save_menu.hide()
	_achievements_menu.hide()
	_cosmetics_menu.show()
