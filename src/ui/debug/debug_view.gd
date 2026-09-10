extends Control


func _ready() -> void:
	if not OS.is_debug_build():
		queue_free()
		return
