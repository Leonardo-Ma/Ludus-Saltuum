extends Node

signal checkpoint_activated(checkpoint_position: Vector3)
signal checkpoint_loaded(checkpoint_position: Vector3) # TODO Check if refactor needed elsewhere to use this instead

const CHECKPOINT_RESPAWN_DELAY: float = 1.0

var _active_checkpoint: Checkpoint = null
var _checkpoint_chunk_key: int = CheckpointSaveData.WORLD_CHECKPOINT_KEY
var _checkpoint_local_transform: Transform3D = Transform3D.IDENTITY
var _has_valid_position: bool = false


func _ready() -> void:
	ChunkManager.chunk_recycled.connect(_on_chunk_recycled)


# TODO Improve this
func on_checkpoint_activated(new_checkpoint: Checkpoint) -> void:
	var chunk_key: int = CheckpointSaveData.WORLD_CHECKPOINT_KEY
	var local_transform: Transform3D = new_checkpoint.global_transform
	if is_instance_valid(new_checkpoint.parent_chunk):
		chunk_key = new_checkpoint.parent_chunk.chunk_key
		assert(ChunkManager.get_chunk_by_key(chunk_key) == new_checkpoint.parent_chunk, "Checkpoint chunk missing in " + name)
		local_transform = new_checkpoint.parent_chunk.global_transform.affine_inverse() * local_transform

	if _active_checkpoint and is_instance_valid(_active_checkpoint) and _active_checkpoint != new_checkpoint:
		_active_checkpoint.deactivate_checkpoint()

	_active_checkpoint = new_checkpoint
	_checkpoint_chunk_key = chunk_key
	_checkpoint_local_transform = local_transform
	_has_valid_position = true
	checkpoint_activated.emit(get_respawn_position())


# TODO Check if argument is necessary
func _on_chunk_recycled(recycled_chunk: LevelChunk) -> void:
	if _checkpoint_chunk_key == recycled_chunk.chunk_key:
		reset_checkpoint()


func get_respawn_transform() -> Transform3D:
	assert(_has_valid_position, "No active checkpoint found in " + name)

	if _checkpoint_chunk_key == CheckpointSaveData.WORLD_CHECKPOINT_KEY:
		return Transform3D(_checkpoint_local_transform.basis.orthonormalized(), _checkpoint_local_transform.origin)

	var chunk: LevelChunk = ChunkManager.get_chunk_by_key(_checkpoint_chunk_key)
	assert(chunk != null, "Checkpoint chunk missing in " + name)

	var transform: Transform3D = chunk.global_transform * _checkpoint_local_transform
	# Strip scaling
	transform.basis = transform.basis.orthonormalized()
	return transform


func get_respawn_position() -> Vector3:
	return get_respawn_transform().origin


func has_active_checkpoint() -> bool:
	if not _has_valid_position:
		return false

	return _checkpoint_chunk_key == CheckpointSaveData.WORLD_CHECKPOINT_KEY or ChunkManager.get_chunk_by_key(_checkpoint_chunk_key) != null


func get_active_checkpoint() -> Checkpoint:
	return _active_checkpoint


func reset_checkpoint() -> void:
	if _active_checkpoint and is_instance_valid(_active_checkpoint):
		_active_checkpoint.deactivate_checkpoint()

	_active_checkpoint = null
	_checkpoint_chunk_key = CheckpointSaveData.WORLD_CHECKPOINT_KEY
	_checkpoint_local_transform = Transform3D.IDENTITY
	_has_valid_position = false


func get_default_spawn_transform() -> Transform3D:
	var chunks: Array[LevelChunk] = ChunkManager.get_active_chunks()
	if chunks.is_empty(): # TODO Double check if this case should fallback to identity (0,0,0)
		return Transform3D.IDENTITY

	var entrance: Node3D = chunks[0].entrance_trigger
	return entrance.global_transform


func get_default_spawn_position() -> Vector3:
	return get_default_spawn_transform().origin


func respawn_at_required_checkpoint() -> void:
	assert(_has_valid_position, "No required checkpoint found in " + name)

	var respawn_transform: Transform3D = get_respawn_transform()
	ControlledEntityEvents.request_respawn(CHECKPOINT_RESPAWN_DELAY, respawn_transform)


#region Save state access
func has_checkpoint_state() -> bool:
	return has_active_checkpoint() and (not is_instance_valid(_active_checkpoint) or _active_checkpoint.save_checkpoint_to_disk)


func get_checkpoint_chunk_key() -> int:
	return _checkpoint_chunk_key


func get_checkpoint_local_transform() -> Transform3D:
	return _checkpoint_local_transform


func restore_checkpoint(chunk_key: int, local_transform: Transform3D) -> void:
	assert(
		chunk_key == CheckpointSaveData.WORLD_CHECKPOINT_KEY or ChunkManager.get_chunk_by_key(chunk_key) != null,
		"Checkpoint chunk missing in " + name,
	)
	_checkpoint_chunk_key = chunk_key
	_checkpoint_local_transform = local_transform
	_active_checkpoint = null
	_has_valid_position = true

	checkpoint_loaded.emit(get_respawn_position())
#endregion
