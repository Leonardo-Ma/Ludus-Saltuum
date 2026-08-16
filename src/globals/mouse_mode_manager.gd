## Centralized mouse mode arbitration via named, priority-ordered requests
class_name MouseModeManager
extends Node

## Highest priority first; first source with an active request wins
const _PRIORITY: Array[StringName] = [&"popup", &"shop", &"menu", &"gameplay", &"device"]

static var _requests: Dictionary[StringName, Input.MouseMode] = {}


static func request_mode(source: StringName, mode: Input.MouseMode) -> void:
	assert(source in _PRIORITY, "MouseModeManager: unknown source '%s', add it to _PRIORITY" % source)
	_requests[source] = mode
	_apply()


static func release(source: StringName) -> void:
	_requests.erase(source)
	_apply()


static func _apply() -> void:
	for source: StringName in _PRIORITY:
		if _requests.has(source):
			Input.mouse_mode = _requests[source]
			return
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
