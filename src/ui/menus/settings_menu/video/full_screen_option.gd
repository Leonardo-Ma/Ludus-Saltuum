extends OptionButton

@export var windowed_icon: Texture2D
@export var maximized_icon: Texture2D
@export var fullscreen_icon: Texture2D
@export var exclusive_fullscreen_icon: Texture2D

var _window_modes: Array[Dictionary] = []
var _last_mode: DisplayServer.WindowMode = DisplayServer.WINDOW_MODE_WINDOWED


func _ready() -> void:
	_window_modes = [
		{&"icon": windowed_icon, &"mode": DisplayServer.WINDOW_MODE_WINDOWED},
		{&"icon": maximized_icon, &"mode": DisplayServer.WINDOW_MODE_MAXIMIZED},
		{&"icon": fullscreen_icon, &"mode": DisplayServer.WINDOW_MODE_FULLSCREEN},
		{&"icon": exclusive_fullscreen_icon, &"mode": DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN},
	]
	_populate()
	item_selected.connect(_on_item_selected)


func _process(_delta: float) -> void:
	var current_mode: DisplayServer.WindowMode = DisplayServer.window_get_mode()
	if current_mode != _last_mode:
		_last_mode = current_mode
		_sync_selection()


func _populate() -> void:
	clear()
	for entry: Dictionary in _window_modes:
		add_icon_item(entry[&"icon"], "")
		set_item_metadata(get_item_count() - 1, entry[&"mode"])
	_sync_selection()


func _sync_selection() -> void:
	var current_mode: DisplayServer.WindowMode = DisplayServer.window_get_mode()
	for i: int in get_item_count():
		if get_item_metadata(i) == current_mode:
			select(i)
			return


func _on_item_selected(index: int) -> void:
	SettingsManager.window_mode = get_item_metadata(index)
	DisplayServer.window_set_mode(SettingsManager.window_mode)
	if SettingsManager.window_mode == DisplayServer.WINDOW_MODE_WINDOWED:
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
	SettingsManager.save()
