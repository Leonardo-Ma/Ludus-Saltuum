## Checks if for every setting there is an equivalent default properly configured
## Does not guarantee the default is correct, just that it exists
extends Node

## Excluded from coverage (they are separate or not primitive)
const _EXCLUDED: Array[StringName] = [&"resolution", &"window_mode", &"environment"]


func _ready() -> void:
	if not OS.is_debug_build():
		queue_free()
		return

	_test_defaults_match_real_properties()
	_test_save_and_load()
	_test_reset_to_default()
	_check_defaults()


func _check_defaults() -> void:
	var all_defaults: Dictionary = {}
	for section: Dictionary in SettingsManager._DEFAULTS.values():
		all_defaults.merge(section)

	for property: Dictionary in SettingsManager.get_property_list():
		if property.usage & PROPERTY_USAGE_SCRIPT_VARIABLE == 0:
			continue
		var key: StringName = property.name
		if key in _EXCLUDED:
			continue
		if (key as String).begins_with("_"):
			continue
		assert(all_defaults.has(key), "SettingsManager: '%s' has no entry in _DEFAULTS" % key)

	print("Settings defaults consistency test completed.")
	self.queue_free()


func _test_defaults_match_real_properties() -> void:
	for section: SettingsManager.SettingsSection in SettingsManager._DEFAULTS:
		for key: StringName in SettingsManager._DEFAULTS[section]:
			assert(key in SettingsManager, "SettingsManager: _DEFAULTS key '%s' has no matching property" % key)


func _test_save_and_load() -> void:
	var original: float = SettingsManager.volume_music
	SettingsManager.volume_music = 0.42
	SettingsManager.save()
	SettingsManager.volume_music = 1.0
	SettingsManager._load()
	assert(is_equal_approx(SettingsManager.volume_music, 0.42), "SettingsManager: save/_load failed for volume_music")
	SettingsManager.volume_music = original
	SettingsManager.save()


func _test_reset_to_default() -> void:
	var section: SettingsManager.SettingsSection = SettingsManager.SettingsSection.AUDIO
	var original: Dictionary = {}
	for key: StringName in SettingsManager._DEFAULTS[section]:
		original[key] = SettingsManager.get(key)

	SettingsManager.volume_effects = 0.1
	SettingsManager.reset_to_default(section)

	var expected: float = SettingsManager._DEFAULTS[section][&"volume_effects"]
	assert(SettingsManager.volume_effects == expected, "SettingsManager: reset_to_default did not restore volume_effects")

	for key: StringName in original:
		SettingsManager.set(key, original[key])
	SettingsManager.save()
