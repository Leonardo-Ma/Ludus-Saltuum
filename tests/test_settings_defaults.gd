## Checks if for every setting there is an equivalent default properly configured
## Does not guarantee the default is correct, just that it exists
extends Node

## Excluded from coverage (they are separate or not primitive)
const _EXCLUDED: Array[StringName] = [&"resolution", &"window_mode", &"environment"]


func _ready() -> void:
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
