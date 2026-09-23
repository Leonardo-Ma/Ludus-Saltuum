## FPS limit selector using common industry presets
extends OptionButton


func _ready() -> void:
	for fps: int in SettingsManager.settings.video.FPS_PRESETS:
		if fps == 0: # Unlimited label
			add_item("9000+")
		else:
			add_item(str(fps))

	SettingsManager.settings_reset.connect(_on_settings_reset)
	item_selected.connect(_on_item_selected)
	_update_selected()


func _on_item_selected(index: int) -> void:
	SettingsManager.settings.video.fps_limit = SettingsManager.settings.video.FPS_PRESETS[index]
	SettingsManager.apply_video()
	SettingsManager.save()


func _on_settings_reset() -> void:
	_update_selected()


func _update_selected() -> void:
	var index: int = SettingsManager.settings.video.FPS_PRESETS.find(SettingsManager.settings.video.fps_limit)
	select(index)
