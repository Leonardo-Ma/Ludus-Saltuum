extends OptionButton

const RESOLUTIONS: Array[Vector2i] = [
	# 16:9
	Vector2i(1280, 720),
	Vector2i(1366, 768),
	Vector2i(1600, 900),
	Vector2i(1920, 1080),
	Vector2i(2560, 1440),
	Vector2i(3840, 2160),
	# 16:10
	Vector2i(1280, 800),
	Vector2i(1920, 1200),
	Vector2i(2560, 1600),
	# Ultrawide 21:9
	Vector2i(2560, 1080),
	Vector2i(3440, 1440),
	# Super ultrawide 32:9
	Vector2i(3840, 1080),
	Vector2i(5120, 1440),
]


func _ready() -> void:
	for resolution: Vector2i in RESOLUTIONS:
		add_item("%d x %d" % [resolution.x, resolution.y])

	SettingsManager.display_settings_changed.connect(_on_display_settings_changed)
	item_selected.connect(_on_resolution_changed)

	_update_selected_resolution()


func _on_display_settings_changed() -> void:
	_update_selected_resolution()


func _update_selected_resolution() -> void:
	var index: int = RESOLUTIONS.find(SettingsManager.resolution)
	select(index)


func _on_resolution_changed(index: int) -> void:
	SettingsManager.resolution = RESOLUTIONS[index]
	SettingsManager.apply_display()
	SettingsManager.save()
