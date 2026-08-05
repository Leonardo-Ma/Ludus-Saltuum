extends Node

signal checkpoint_activated(checkpoint_position: Vector3)

var _active_checkpoint: Checkpoint = null
var _respawn_position: Vector3 = Vector3.ZERO
var _has_valid_position: bool = false


func on_checkpoint_activated(new_checkpoint: Checkpoint) -> void:
	if _active_checkpoint and is_instance_valid(_active_checkpoint) and _active_checkpoint != new_checkpoint:
		_active_checkpoint.deactivate_checkpoint()
	_active_checkpoint = new_checkpoint
	_respawn_position = new_checkpoint.global_position
	_has_valid_position = true
	print_debug("Checkpoint activated at: ", _respawn_position)
	CheckpointManager.checkpoint_activated.emit(_respawn_position)


## Called by SaveManager
func restore_position(position: Vector3) -> void:
	_active_checkpoint = null
	_respawn_position = position
	_has_valid_position = true
	checkpoint_activated.emit(position)


func has_active_checkpoint() -> bool:
	return _has_valid_position


func get_respawn_position() -> Vector3:
	assert(_has_valid_position, "No active checkpoint found. Check if default spawn point defined.")
	return _respawn_position


func get_active_checkpoint() -> Checkpoint:
	return _active_checkpoint
