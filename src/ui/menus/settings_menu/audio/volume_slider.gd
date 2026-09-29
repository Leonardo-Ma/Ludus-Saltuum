## HSlider bound to SoundManager category bus. Set category in Inspector
extends HSlider

@export_category("Audio")
@export var category: SoundManager.SoundCategory


func _ready() -> void:
	assert(category != SoundManager.SoundCategory.UNASSIGNED, "VolumeSlider: category not set in " + name)

	min_value = 0.0
	max_value = 1.0
	step = 0.01
	value = _get_saved_volume()

	value_changed.connect(_on_volume_changed)
	SettingsManager.settings_reset.connect(_on_settings_reset)


func _on_volume_changed(new_value: float) -> void:
	SoundManager.set_category_volume_linear(category, new_value)
	_write_to_manager(new_value)


func _get_saved_volume() -> float:
	match category:
		SoundManager.SoundCategory.GLOBAL:
			return SettingsManager.settings.audio.volume_global
		SoundManager.SoundCategory.MUSIC:
			return SettingsManager.settings.audio.volume_music
		SoundManager.SoundCategory.SFX:
			return SettingsManager.settings.audio.volume_effects
		SoundManager.SoundCategory.UI:
			return SettingsManager.settings.audio.volume_ui
		_:
			return 1.0


func _write_to_manager(new_value: float) -> void:
	match category:
		SoundManager.SoundCategory.GLOBAL:
			SettingsManager.settings.audio.volume_global = new_value
		SoundManager.SoundCategory.MUSIC:
			SettingsManager.settings.audio.volume_music = new_value
		SoundManager.SoundCategory.SFX:
			SettingsManager.settings.audio.volume_effects = new_value
		SoundManager.SoundCategory.UI:
			SettingsManager.settings.audio.volume_ui = new_value

	SettingsManager.save()


func _on_settings_reset() -> void:
	match category:
		SoundManager.SoundCategory.GLOBAL:
			value = SettingsManager.settings.audio.volume_global
		SoundManager.SoundCategory.MUSIC:
			value = SettingsManager.settings.audio.volume_music
		SoundManager.SoundCategory.SFX:
			value = SettingsManager.settings.audio.volume_effects
		SoundManager.SoundCategory.UI:
			value = SettingsManager.settings.audio.volume_ui
