extends OptionButton

## Binds scene-authored window mode item IDs to display settings


func _ready() -> void:
	disabled = OS.has_feature("web")
	item_selected.connect(_on_item_selected)
	SettingsManager.video_settings_changed.connect(_sync_selection)
	get_window().size_changed.connect(_sync_selection)
	visibility_changed.connect(_sync_selection)
	_sync_selection()


func _sync_selection() -> void:
	var index: int = get_item_index(DisplayServer.window_get_mode())
	if index >= 0:
		select(index)


func _on_item_selected(index: int) -> void:
	SettingsManager.settings.video.window_mode = get_item_id(index)
	SettingsManager.apply_window()
	SettingsManager.save()
