class_name SettingsTabButton
extends UIButton

signal tab_activated(panel: VBoxContainer, section: SettingsManager.SettingsSection)

@export var panel: VBoxContainer
@export var section: SettingsManager.SettingsSection


func _button_ready() -> void:
	assert(toggle_mode == true, "Enable toggle mode for " + name)


func _button_pressed() -> void:
	tab_activated.emit(panel, section)
