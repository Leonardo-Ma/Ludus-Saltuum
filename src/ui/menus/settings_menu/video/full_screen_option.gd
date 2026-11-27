extends OptionButton

var _last_mode: DisplayServer.WindowMode = DisplayServer.WINDOW_MODE_WINDOWED


func _ready() -> void:
	disabled = OS.has_feature("web")
	_sync_selection()
	item_selected.connect(_on_item_selected)


func _process(_delta: float) -> void:
	var current_mode: DisplayServer.WindowMode = DisplayServer.window_get_mode()
	if current_mode != _last_mode:
		_last_mode = current_mode
		_sync_selection()


func _sync_selection() -> void:
	var index: int = get_item_index(DisplayServer.window_get_mode())
	if index >= 0:
		select(index)


func _on_item_selected(index: int) -> void:
	SettingsManager.settings.video.window_mode = get_item_id(index)
	SettingsManager.apply_window()
	SettingsManager.save()
