extends HSlider


func _ready() -> void:
	value = SettingsManager.settings.camera.camera_fov
	value_changed.connect(_on_value_changed)
	SettingsManager.settings_reset.connect(_on_settings_reset)


func _on_value_changed(new_value: float) -> void:
	SettingsManager.settings.camera.camera_fov = new_value
	SettingsManager.save()
	SettingsManager.apply_camera()


func _on_settings_reset() -> void:
	value = SettingsManager.settings.camera.camera_fov
