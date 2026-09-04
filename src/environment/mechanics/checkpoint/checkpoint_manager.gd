extends Node

signal checkpoint_activated(checkpoint_position: Vector3)
signal checkpoint_loaded(checkpoint_position: Vector3) # TODO Check if refactor needed elsewhere to use this instead
## Unconditional, fires at the end of apply_save() regardless of a valid checkpoint
signal load_applied

var _active_checkpoint: Checkpoint = null
var _checkpoint_chunk_index: int = -1
var _checkpoint_local_transform: Transform3D = Transform3D.IDENTITY
var _has_valid_position: bool = false


func _ready() -> void:
	LevelChunkManager.chunk_recycled.connect(_on_chunk_recycled)

	SaveManager.save_requested.connect(
		func(data: SaveData) -> void:
			build_save(data.checkpoint),
	)
	LevelChunkManager.level_loaded.connect(_on_level_loaded)
	SaveManager.reset_requested.connect(reset_checkpoint)


func _on_level_loaded(data: CheckpointSaveData) -> void:
	apply_save(data)


# TODO Improve this
func on_checkpoint_activated(new_checkpoint: Checkpoint) -> void:
	if _active_checkpoint and is_instance_valid(_active_checkpoint) and _active_checkpoint != new_checkpoint:
		_active_checkpoint.deactivate_checkpoint()

	_active_checkpoint = new_checkpoint

	if new_checkpoint.parent_chunk and is_instance_valid(new_checkpoint.parent_chunk):
		_checkpoint_chunk_index = LevelChunkManager.get_active_chunks().find(new_checkpoint.parent_chunk)
		assert(_checkpoint_chunk_index >= 0, "Checkpoint chunk missing in " + name)

		_checkpoint_local_transform = (new_checkpoint.parent_chunk.global_transform.affine_inverse() * new_checkpoint.global_transform)
	else:
		_checkpoint_chunk_index = -1
		_checkpoint_local_transform = new_checkpoint.global_transform

	_has_valid_position = true
	checkpoint_activated.emit(get_respawn_position())


# TODO Check if argument is necessary
func _on_chunk_recycled(_recycled_chunk: LevelChunk) -> void:
	if _checkpoint_chunk_index == -1:
		return

	if _checkpoint_chunk_index == 0:
		reset_checkpoint()
		return

	_checkpoint_chunk_index -= 1


func get_respawn_transform() -> Transform3D:
	assert(_has_valid_position, "No active checkpoint found in " + name)

	if _checkpoint_chunk_index == -1:
		return Transform3D(_checkpoint_local_transform.basis.orthonormalized(), _checkpoint_local_transform.origin)

	var active_chunks: Array[LevelChunk] = LevelChunkManager.get_active_chunks()
	assert(_checkpoint_chunk_index < active_chunks.size(), "Checkpoint chunk index out of range in " + name)

	var transform: Transform3D = active_chunks[_checkpoint_chunk_index].global_transform * _checkpoint_local_transform
	# Strip scaling
	transform.basis = transform.basis.orthonormalized()
	return transform


func get_respawn_position() -> Vector3:
	return get_respawn_transform().origin


func has_active_checkpoint() -> bool:
	if not _has_valid_position:
		return false

	if _checkpoint_chunk_index == -1:
		return true

	var active_chunks: Array[LevelChunk] = LevelChunkManager.get_active_chunks()
	return _checkpoint_chunk_index < active_chunks.size()


func get_active_checkpoint() -> Checkpoint:
	return _active_checkpoint


func reset_checkpoint() -> void:
	if _active_checkpoint and is_instance_valid(_active_checkpoint):
		_active_checkpoint.deactivate_checkpoint()

	_active_checkpoint = null
	_checkpoint_chunk_index = -1
	_checkpoint_local_transform = Transform3D.IDENTITY
	_has_valid_position = false


func get_default_spawn_transform() -> Transform3D:
	var chunks: Array[LevelChunk] = LevelChunkManager.get_active_chunks()
	if chunks.is_empty(): # TODO Double check if this case should fallback to identity (0,0,0)
		return Transform3D.IDENTITY

	var entrance: Node3D = chunks[0].get_node("%EntranceTrigger")
	return entrance.global_transform


func get_default_spawn_position() -> Vector3:
	return get_default_spawn_transform().origin

#region Save and Load
func build_save(data: CheckpointSaveData) -> void:
	data.has_checkpoint_position = _has_valid_position

	if not data.has_checkpoint_position:
		return

	data.checkpoint_chunk_index = _checkpoint_chunk_index
	data.checkpoint_local_transform = _checkpoint_local_transform


func apply_save(data: CheckpointSaveData) -> void:
	if not data.has_checkpoint_position:
		reset_checkpoint()
		load_applied.emit()
		return

	_checkpoint_chunk_index = data.checkpoint_chunk_index
	_checkpoint_local_transform = data.checkpoint_local_transform
	_active_checkpoint = null
	_has_valid_position = true

	if _checkpoint_chunk_index >= 0:
		var active_chunks: Array[LevelChunk] = LevelChunkManager.get_active_chunks()
		assert(_checkpoint_chunk_index < active_chunks.size(), "Checkpoint chunk index out of range in " + name)

	checkpoint_loaded.emit(get_respawn_position())
	load_applied.emit()
#endregion
