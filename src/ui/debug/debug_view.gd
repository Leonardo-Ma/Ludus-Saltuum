class_name DebugView
extends Control

@onready var _label: PlayerDebugLabel = %Label


func _ready() -> void:
	if not OS.is_debug_build():
		queue_free()
		return


func bind_player(player: PlayerEntity, movement: PlayerMovementComponent) -> void:
	_label.bind_player(player, movement)
