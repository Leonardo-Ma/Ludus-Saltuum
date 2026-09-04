extends Node

var _pause_sources: Dictionary = { }


func request_pause(source_name: String) -> void:
	if not _pause_sources.has(source_name):
		_pause_sources[source_name] = true
		_update_pause_state()
		print_debug("Pausing ", source_name)


func release_pause(source_name: String) -> void:
	if _pause_sources.has(source_name):
		_pause_sources.erase(source_name)
		_update_pause_state()
		print_debug("Unpausing ", source_name)


func _update_pause_state() -> void:
	get_tree().paused = _pause_sources.size() > 0


func is_paused() -> bool:
	return get_tree().paused
