extends OptionButton


func _ready() -> void:
	SettingsManager.video_settings_changed.connect(_on_video_settings_changed)
	item_selected.connect(_on_resolution_changed)

	_update_options()


func _on_video_settings_changed() -> void:
	_update_options()


func _update_options() -> void:
	clear()

	if not SettingsManager.is_windowed_resolution_editable():
		var display_resolution: Vector2i = SettingsManager.get_current_display_resolution()
		add_item("%d x %d" % [display_resolution.x, display_resolution.y])
		select(0)
		disabled = true
		return

	var resolutions: Array[Vector2i] = SettingsManager.get_windowed_resolutions()

	for resolution: Vector2i in resolutions:
		add_item("%d x %d" % [resolution.x, resolution.y])

	disabled = false

	var current_size: Vector2i = SettingsManager.settings.video.windowed_size
	var index: int = resolutions.find(current_size)

	if index >= 0:
		select(index)


func _on_resolution_changed(index: int) -> void:
	if not SettingsManager.is_windowed_resolution_editable():
		return

	var resolutions: Array[Vector2i] = SettingsManager.get_windowed_resolutions()
	assert(index >= 0 and index < resolutions.size(), "Invalid resolution index in " + name)

	SettingsManager.set_windowed_size(resolutions[index])
