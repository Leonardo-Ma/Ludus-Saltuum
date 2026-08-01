class_name Main
extends Node


func _ready() -> void:
	ApplicationStateManager.gameplay_started.connect(_on_gameplay_started)


func _on_gameplay_started() -> void:
	LevelChunkManager.initialize_level()
