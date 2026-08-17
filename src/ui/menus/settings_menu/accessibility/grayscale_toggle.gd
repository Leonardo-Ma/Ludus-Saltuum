extends CheckButton


func _ready() -> void:
	button_pressed = SettingsManager.grayscale_enabled
	toggled.connect(_on_toggled)
	SettingsManager.settings_reset.connect(_on_settings_reset)


func _on_toggled(toggled_on: bool) -> void:
	SettingsManager.grayscale_enabled = toggled_on
	SettingsManager.save()
	SettingsManager.apply_display()


func _on_settings_reset() -> void:
	button_pressed = SettingsManager.grayscale_enabled
