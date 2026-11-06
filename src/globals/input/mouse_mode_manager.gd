class_name MouseModeManager
extends Node

## Centralized mouse mode arbitration via named, priority-ordered requests

## Highest priority first; first source with an active request wins [br]
## NOTE Use explicit names instead of values to allow reordering
enum Source {
	POPUP = 0, ## Example: Popup is highest priority here
	MENU = 1,
	GAMEPLAY = 2,
	DEVICE = 3,
}

static var _requests: Dictionary[Source, Input.MouseMode] = { }


static func request_mode(source: Source, mode: Input.MouseMode) -> void:
	_requests[source] = mode
	_apply()


static func release(source: Source) -> void:
	_requests.erase(source)
	_apply()


static func _apply() -> void:
	for source: Source in Source.values():
		if _requests.has(source):
			var requested_mode: Input.MouseMode = _requests[source]

			if OS.has_feature("web") and requested_mode == Input.MOUSE_MODE_CAPTURED:
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

			Input.mouse_mode = requested_mode
			return

	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
