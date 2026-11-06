extends SaveController

## Persists CheckpointManager state. Must be autoloaded before ChunkSaveController, checkpoint restore runs after chunks are restored

## Unconditional, fires at the end of apply_save_data() regardless of a valid checkpoint
signal load_applied

var _pending_data: CheckpointSaveData


func _child_ready() -> void:
	SaveManager.load_requested.connect(_on_load_requested)
	ChunkManager.level_loaded.connect(_on_level_loaded)


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


func apply_save_data(data: CheckpointSaveData) -> void:
	if data.has_checkpoint_position:
		CheckpointManager.restore_checkpoint(data.checkpoint_chunk_index, data.checkpoint_local_transform)
	else:
		CheckpointManager.reset_checkpoint()
	load_applied.emit()


func _on_load_requested(data: SaveData) -> void:
	_pending_data = data.checkpoint


func _on_level_loaded() -> void:
	assert(_pending_data != null, "Checkpoint data missing in " + name + ", autoload it before ChunkSaveController")
	apply_save_data(_pending_data)
	_pending_data = null
