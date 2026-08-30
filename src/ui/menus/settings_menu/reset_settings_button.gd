## Resets settings for the currently visible tab's section back to default
extends UITextureButton

@export var tabs_controller: OptionsTabController

var _current_section: SettingsManager.SettingsSection = SettingsManager.SettingsSection.NONE


func _button_ready() -> void:
	assert(tabs_controller != null, "ResetSettingsButton: tabs_controller not assigned in " + name)
	tabs_controller.active_section_changed.connect(_on_active_section_changed)


func _on_active_section_changed(section: SettingsManager.SettingsSection) -> void:
	_current_section = section
	disabled = section == SettingsManager.SettingsSection.NONE


func _button_pressed() -> void:
	if _current_section == SettingsManager.SettingsSection.KEY_BINDINGS:
		InputBindingManager.reset_all()
	SettingsManager.reset_to_default(_current_section)
