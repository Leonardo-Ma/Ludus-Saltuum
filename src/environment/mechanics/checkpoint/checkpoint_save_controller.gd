extends SaveController

## Persists CheckpointManager state, checkpoint restore runs after chunks are restored


func _child_ready() -> void:
	pass


func _on_save_requested(data: SaveData) -> void:
	build_save_data(data.checkpoint)


func initialize_new_save_data() -> void:
	CheckpointManager.reset_checkpoint()


func build_save_data(data: CheckpointSaveData) -> void:
	data.has_checkpoint_position = CheckpointManager.has_checkpoint_state()

	if not data.has_checkpoint_position:
		return

	data.checkpoint_chunk_index = CheckpointManager.get_checkpoint_chunk_index()
	data.checkpoint_local_transform = CheckpointManager.get_checkpoint_local_transform()


func can_apply_save_data(data: CheckpointSaveData, chunk_count: int) -> bool:
	if not data.has_checkpoint_position:
		return true
	var transform: Transform3D = data.checkpoint_local_transform
	var determinant: float = transform.basis.determinant()
	return (
		CheckpointSaveData.is_valid_chunk_index(data.checkpoint_chunk_index, chunk_count)
		and transform.is_finite() and is_finite(determinant) and not is_zero_approx(determinant)
	)


func apply_save_data(data: CheckpointSaveData) -> void:
	CheckpointManager.reset_checkpoint()
	if data.has_checkpoint_position:
		CheckpointManager.restore_checkpoint(data.checkpoint_chunk_index, data.checkpoint_local_transform)
