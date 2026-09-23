## To a adjust display (brightness, contrast, saturation)
extends HSlider

enum DisplayProperty {
	BRIGHTNESS = 0,
	CONTRAST = 1,
	SATURATION = 2,
}

const _DB_MAX: float = 1.5
const _DB_MIN: float = 0.5

@export var property: DisplayProperty


func _ready() -> void:
	assert(property != null, "DisplaySlider: property not set in " + name)
	min_value = _DB_MIN
	max_value = _DB_MAX
	value = _get_saved_value()
	value_changed.connect(_on_value_changed)
	SettingsManager.settings_reset.connect(_on_settings_reset)


func _on_value_changed(new_value: float) -> void:
	match property:
		DisplayProperty.BRIGHTNESS:
			SettingsManager.settings.video.brightness = new_value
		DisplayProperty.CONTRAST:
			SettingsManager.settings.video.contrast = new_value
		DisplayProperty.SATURATION:
			SettingsManager.settings.video.saturation = new_value
	SettingsManager.apply_video()
	SettingsManager.save()


func _get_saved_value() -> float:
	match property:
		DisplayProperty.BRIGHTNESS:
			return SettingsManager.settings.video.brightness
		DisplayProperty.CONTRAST:
			return SettingsManager.settings.video.contrast
		DisplayProperty.SATURATION:
			return SettingsManager.settings.video.saturation
	return 1.0


func _on_settings_reset() -> void:
	match property:
		DisplayProperty.BRIGHTNESS:
			value = SettingsManager.settings.video.brightness
		DisplayProperty.CONTRAST:
			value = SettingsManager.settings.video.contrast
		DisplayProperty.SATURATION:
			value = SettingsManager.settings.video.saturation
