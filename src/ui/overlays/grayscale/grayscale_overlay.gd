## Full-screen grayscale toggle, affects world and UI
extends CanvasLayer

@onready var _overlay_rect: ColorRect = %GrayscaleRect


func _ready() -> void:
	_overlay_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	SettingsManager.accessibility_settings_changed.connect(_on_accessibility_settings_changed)
	_on_accessibility_settings_changed()


func _on_accessibility_settings_changed() -> void:
	visible = SettingsManager.settings.accessibility.grayscale_enabled
