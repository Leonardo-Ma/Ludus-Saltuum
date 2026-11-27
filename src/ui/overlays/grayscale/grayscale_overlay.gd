## Full-screen grayscale toggle, affects world and UI
extends CanvasLayer

func _ready() -> void:
	SettingsManager.accessibility_settings_changed.connect(_on_accessibility_settings_changed)
	_on_accessibility_settings_changed()


func _on_accessibility_settings_changed() -> void:
	visible = SettingsManager.settings.accessibility.grayscale_enabled
