## HSlider bound to AudioManager category bus. Set category in Inspector
extends HSlider

@export_category("Audio")
@export var bus: AudioManager.SoundBus = AudioManager.SoundBus.UNASSIGNED


func _ready() -> void:
	assert(bus != AudioManager.SoundBus.UNASSIGNED, "VolumeSlider: category not set in " + name)

	min_value = 0.0
	max_value = 1.0
	step = 0.01
	value = _get_saved_volume()

	value_changed.connect(_on_volume_changed)
	SettingsManager.settings_reset.connect(_on_settings_reset)


func _on_volume_changed(new_value: float) -> void:
	AudioManager.set_bus_volume_linear(bus, new_value)
	_write_to_manager(new_value)


func _get_saved_volume() -> float:
	match bus:
		AudioManager.SoundBus.MASTER:
			return SettingsManager.settings.audio.volume_master
		AudioManager.SoundBus.MUSIC:
			return SettingsManager.settings.audio.volume_music
		AudioManager.SoundBus.SFX:
			return SettingsManager.settings.audio.volume_effects
		AudioManager.SoundBus.UI:
			return SettingsManager.settings.audio.volume_ui
		_:
			return 1.0


func _write_to_manager(new_value: float) -> void:
	match bus:
		AudioManager.SoundBus.MASTER:
			SettingsManager.settings.audio.volume_master = new_value
		AudioManager.SoundBus.MUSIC:
			SettingsManager.settings.audio.volume_music = new_value
		AudioManager.SoundBus.SFX:
			SettingsManager.settings.audio.volume_effects = new_value
		AudioManager.SoundBus.UI:
			SettingsManager.settings.audio.volume_ui = new_value

	SettingsManager.save()


func _on_settings_reset() -> void:
	match bus:
		AudioManager.SoundBus.MASTER:
			value = SettingsManager.settings.audio.volume_master
		AudioManager.SoundBus.MUSIC:
			value = SettingsManager.settings.audio.volume_music
		AudioManager.SoundBus.SFX:
			value = SettingsManager.settings.audio.volume_effects
		AudioManager.SoundBus.UI:
			value = SettingsManager.settings.audio.volume_ui
