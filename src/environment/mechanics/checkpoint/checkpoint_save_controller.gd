## Handles checkpoint save/load logic for player respawn position [br]
## Used by SaveManager during save/load operations
class_name CheckpointSaveController
extends RefCounted

# Internal state for deferred player placement
static var _pending_load_data: CheckpointSaveData = null


static func build_save(data: CheckpointSaveData) -> void:
	data.has_checkpoint_position = CheckpointManager.has_active_checkpoint()

	if data.has_checkpoint_position:
		var checkpoint: Checkpoint = CheckpointManager.get_active_checkpoint()
		if checkpoint.parent_chunk and is_instance_valid(checkpoint.parent_chunk):
			# Chunk relative checkpoint
			data.checkpoint_chunk_scene_path = checkpoint.parent_chunk.scene_file_path
			data.checkpoint_local_transform = checkpoint.parent_chunk.global_transform.affine_inverse() * checkpoint.global_transform
		else:
			# Global checkpoint (outside chunks)
			data.checkpoint_chunk_scene_path = ""
			data.checkpoint_local_transform = Transform3D.IDENTITY
			data.checkpoint_local_transform.origin = checkpoint.global_position


## Player can be null if player not spawned
static func apply_save(data: CheckpointSaveData, player: PlayerEntity = null) -> void:
	if not data.has_checkpoint_position:
		return

	CheckpointManager.restore_position(data.checkpoint_chunk_scene_path, data.checkpoint_local_transform)

	if player and is_instance_valid(player):
		_place_player_at_checkpoint(player)
	else:
		# Player not ready yet, store for deferred placement
		_pending_load_data = data


static func reset_data() -> void:
	CheckpointManager.reset_checkpoint()
	_pending_load_data = null


static func _place_player_at_checkpoint(player: PlayerEntity) -> void:
	if not is_instance_valid(player):
		return

	player.global_position = CheckpointManager.get_respawn_position()
	player.velocity = Vector3.ZERO
	player.movement_controller.movement_enabled = true
	player.movement_controller.disable_timer = 0.0


## Called when player spawns after a load to apply any pending checkpoint
static func on_player_spawned_after_load(player: PlayerEntity) -> void:
	if _pending_load_data == null:
		return

	if is_instance_valid(player):
		_place_player_at_checkpoint(player)

	_pending_load_data = null
