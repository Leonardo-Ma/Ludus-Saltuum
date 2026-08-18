## HSlider bound to a SoundManager category bus. Set category in the Inspector.
extends HSlider

const _DB_MAX: float = 6.0

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
	var db: float = linear_to_db(new_value) + _DB_MAX
	SoundManager.set_category_volume(category, db)
	_write_to_manager(new_value)
	SettingsManager.save()


func _get_saved_volume() -> float:
	match category:
		SoundManager.SoundCategory.GLOBAL:
			return SettingsManager.volume_global
		SoundManager.SoundCategory.MUSIC:
			return SettingsManager.volume_music
		SoundManager.SoundCategory.SFX:
			return SettingsManager.volume_effects
		SoundManager.SoundCategory.UI:
			return SettingsManager.volume_ui
		_:
			return 1.0


func _write_to_manager(new_value: float) -> void:
	match category:
		SoundManager.SoundCategory.GLOBAL:
			SettingsManager.volume_global = new_value
		SoundManager.SoundCategory.MUSIC:
			SettingsManager.volume_music = new_value
		SoundManager.SoundCategory.SFX:
			SettingsManager.volume_effects = new_value
		SoundManager.SoundCategory.UI:
			SettingsManager.volume_ui = new_value


func _on_settings_reset() -> void:
	match category:
		SoundManager.SoundCategory.GLOBAL:
			value = SettingsManager.volume_global
		SoundManager.SoundCategory.MUSIC:
			value = SettingsManager.volume_music
		SoundManager.SoundCategory.SFX:
			value = SettingsManager.volume_effects
		SoundManager.SoundCategory.UI:
			value = SettingsManager.volume_ui
