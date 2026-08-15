## Centralized mouse mode arbitration via named, priority-ordered requests
extends Node

## Highest priority first; first source with an active request wins
const _PRIORITY: Array[StringName] = [&"popup", &"shop", &"menu", &"gameplay", &"device"]

var _requests: Dictionary[StringName, Input.MouseMode] = {}


func request_mode(source: StringName, mode: Input.MouseMode) -> void:
	assert(source in _PRIORITY, "MouseModeManager: unknown source '%s', add it to _PRIORITY" % source)
	_requests[source] = mode
	_apply()


func release(source: StringName) -> void:
	_requests.erase(source)
	_apply()


func _apply() -> void:
	for source: StringName in _PRIORITY:
		if _requests.has(source):
			Input.mouse_mode = _requests[source]
			return
