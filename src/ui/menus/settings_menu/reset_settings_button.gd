extends UIButton

## Resets settings for the currently visible tab's section back to default

@export var tabs_controller: TabController

var _current_section: SettingsManager.SettingsSection = SettingsManager.SettingsSection.NONE


func _button_ready() -> void:
	assert(tabs_controller != null, "ResetSettingsButton: tabs_controller not assigned in " + name)
	tabs_controller.tab_changed.connect(_on_tab_changed)


func _on_tab_changed(tab: TabButton) -> void:
	var settings_tab: SettingsTabButton = tab
	_current_section = settings_tab.section if settings_tab != null else SettingsManager.SettingsSection.NONE
	disabled = _current_section == SettingsManager.SettingsSection.NONE


func _button_pressed() -> void:
	if _current_section == SettingsManager.SettingsSection.KEY_BINDINGS:
		InputBindingManager.reset_all()
	SettingsManager.reset_to_default(_current_section)
