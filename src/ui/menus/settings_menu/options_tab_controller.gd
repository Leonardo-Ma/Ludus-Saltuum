# TODO Check if force same order is best approach
# BUG This is clearly wrong, probably a dictionary better?
## Manages tab switching for the settings menu
## Tabs, panels, and section_map must be in same order
class_name OptionsTabController
extends VBoxContainer

signal active_section_changed(section: SettingsManager.SettingsSection)

@export var tabs: Array[Button] = []
@export var panels: Array[VBoxContainer] = []
## Maps each tab/panel index to the settings section it resets
@export var section_map: Array[SettingsManager.SettingsSection] = []


func _ready() -> void:
	assert(tabs.size() == panels.size(), "Tab/panel count mismatch in " + name)
	assert(tabs.size() == section_map.size(), "Tab/section_map count mismatch in " + name)
	var group: ButtonGroup = ButtonGroup.new()
	for i: int in tabs.size():
		tabs[i].toggle_mode = true
		tabs[i].button_group = group
		tabs[i].pressed.connect(_show_panel.bind(i))
	tabs[0].button_pressed = true
	_show_panel(0)


func _show_panel(index: int) -> void:
	for i: int in panels.size():
		panels[i].visible = i == index
	active_section_changed.emit(section_map[index])
