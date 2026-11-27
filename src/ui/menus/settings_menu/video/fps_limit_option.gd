## FPS limit selector using common industry presets
## Unlimited label uses item ID 0
extends OptionButton


func _ready() -> void:
	SettingsManager.settings_reset.connect(_on_settings_reset)
	item_selected.connect(_on_item_selected)
	_update_selected()


func _on_item_selected(index: int) -> void:
	SettingsManager.settings.video.fps_limit = get_item_id(index)
	SettingsManager.apply_video()
	SettingsManager.save()


func _on_settings_reset() -> void:
	_update_selected()


func _update_selected() -> void:
	select(get_item_index(SettingsManager.settings.video.fps_limit))
