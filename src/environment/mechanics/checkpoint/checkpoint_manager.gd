extends Node

signal checkpoint_activated(checkpoint_position: Vector3)

var _active_checkpoint: Checkpoint = null
var _active_checkpoint_chunk: LevelChunk = null

var _local_checkpoint_transform: Transform3D = Transform3D.IDENTITY
var _has_valid_position: bool = false
var _is_chunk_relative: bool = false


func _ready() -> void:
	LevelChunkManager.chunk_recycled.connect(_on_chunk_recycled)


# TODO Improve this
func on_checkpoint_activated(new_checkpoint: Checkpoint) -> void:
	if _active_checkpoint and is_instance_valid(_active_checkpoint) and _active_checkpoint != new_checkpoint:
		_active_checkpoint.deactivate_checkpoint()
	_active_checkpoint = new_checkpoint

	if new_checkpoint.parent_chunk and is_instance_valid(new_checkpoint.parent_chunk):
		# Checkpoint inside a LevelChunk, store chunk relative transform
		_active_checkpoint_chunk = new_checkpoint.parent_chunk
		_local_checkpoint_transform = _active_checkpoint_chunk.global_transform.affine_inverse() * new_checkpoint.global_transform
		_is_chunk_relative = true
		print_debug(
			"Checkpoint activated (chunk relative) at local: ", _local_checkpoint_transform.origin, " in chunk: ", _active_checkpoint_chunk.name
		)
	else:
		# Checkpoint outside LevelChunk (tutorial, etc.), store global position directly
		_active_checkpoint_chunk = null
		_local_checkpoint_transform = Transform3D.IDENTITY
		_local_checkpoint_transform.origin = new_checkpoint.global_position
		_is_chunk_relative = false
		print_debug("Checkpoint activated (global) at: ", new_checkpoint.global_position)

	_has_valid_position = true
	checkpoint_activated.emit(get_respawn_position())


func _on_chunk_recycled(recycled_chunk: LevelChunk) -> void:
	# Only invalidate if checkpoint was chunk-relative AND its chunk was recycled
	if _is_chunk_relative and _active_checkpoint_chunk and is_instance_valid(_active_checkpoint_chunk) and _active_checkpoint_chunk == recycled_chunk:
		print_debug("Active checkpoint's chunk recycled, invalidating respawn position")
		_has_valid_position = false
		_active_checkpoint = null
		_active_checkpoint_chunk = null
		_local_checkpoint_transform = Transform3D.IDENTITY
		_is_chunk_relative = false


func get_respawn_transform() -> Transform3D:
	assert(_has_valid_position, "No active checkpoint found. Check if default spawn point defined.")
	if _is_chunk_relative:
		assert(_active_checkpoint_chunk != null and is_instance_valid(_active_checkpoint_chunk), "Checkpoint chunk no longer valid")
		# World position from chunk current transform + local offset
		return _active_checkpoint_chunk.global_transform * _local_checkpoint_transform
	return _local_checkpoint_transform


func get_respawn_position() -> Vector3:
	return get_respawn_transform().origin


func has_active_checkpoint() -> bool:
	if not _has_valid_position:
		return false
	if _is_chunk_relative:
		return _active_checkpoint_chunk != null and is_instance_valid(_active_checkpoint_chunk)
	return true  # Global checkpoint never become invalid from chunk recycling


func get_active_checkpoint() -> Checkpoint:
	return _active_checkpoint


func reset_checkpoint() -> void:
	_active_checkpoint = null
	_active_checkpoint_chunk = null
	_local_checkpoint_transform = Transform3D.IDENTITY
	_has_valid_position = false
	_is_chunk_relative = false


func get_default_spawn_transform() -> Transform3D:
	# Fallback to first chunk entrance if available
	var chunks: Array[LevelChunk] = LevelChunkManager.get_active_chunks()
	if not chunks.is_empty():
		var entrance: Node3D = chunks[0].get_node("%EntranceTrigger")
		if entrance and is_instance_valid(entrance):
			return entrance.global_transform
	# Fallback to world origin
	return Transform3D.IDENTITY


func get_default_spawn_position() -> Vector3:
	return get_default_spawn_transform().origin


func restore_position(chunk_scene_path: String, local_transform: Transform3D) -> void:
	if chunk_scene_path == "":
		# Global checkpoint (no chunk), restore directly from local_transform.origin
		_active_checkpoint_chunk = null
		_local_checkpoint_transform = local_transform
		_is_chunk_relative = false
		_has_valid_position = true
		_active_checkpoint = null
		checkpoint_activated.emit(get_respawn_position())
		return

	# Chunk relative checkpoint, find matching active chunk
	for chunk: LevelChunk in LevelChunkManager.get_active_chunks():
		if chunk.scene_file_path == chunk_scene_path:
			_active_checkpoint_chunk = chunk
			_local_checkpoint_transform = local_transform
			_is_chunk_relative = true
			_has_valid_position = true
			_active_checkpoint = null
			checkpoint_activated.emit(get_respawn_position())
			return

	# Fallback, chunk not found (possibly recycled between save and load)
	_has_valid_position = false
	push_error("CheckpointManager: Could not find chunk '" + chunk_scene_path + "' for restore_position")
