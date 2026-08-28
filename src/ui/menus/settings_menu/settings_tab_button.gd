class_name SettingsTabButton
extends Button

signal tab_activated(panel: VBoxContainer, section: SettingsManager.SettingsSection)

@export var panel: VBoxContainer
@export var section: SettingsManager.SettingsSection


func _ready() -> void:
	assert(toggle_mode == true, "Enable toggle mode for " + name)
	pressed.connect(func() -> void: tab_activated.emit(panel, section))
