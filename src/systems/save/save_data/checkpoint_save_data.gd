class_name CheckpointSaveData
extends Resource

const WORLD_CHECKPOINT_INDEX: int = -1
const WORLD_CHECKPOINT_KEY: int = -1
const LEGACY_CHUNK_REFERENCE: int = -2

## NOTE Legacy field, -1 for world checkpoints, 0 or greater for active chunk indices
@export var checkpoint_chunk_index: int = WORLD_CHECKPOINT_INDEX
## -1 for world checkpoints, 0 or greater for stable chunk keys
@export var checkpoint_chunk_key: int = LEGACY_CHUNK_REFERENCE

## World transform for world checkpoints, relative to chunk origin otherwise
@export var checkpoint_local_transform: Transform3D = Transform3D.IDENTITY

@export var has_checkpoint_position: bool = false


func resolve_chunk_key(active_chunk_keys: Array[int]) -> int:
	if checkpoint_chunk_key != LEGACY_CHUNK_REFERENCE:
		return checkpoint_chunk_key
	if checkpoint_chunk_index == WORLD_CHECKPOINT_INDEX:
		return WORLD_CHECKPOINT_KEY
	if checkpoint_chunk_index >= 0 and checkpoint_chunk_index < active_chunk_keys.size():
		return active_chunk_keys[checkpoint_chunk_index]
	return LEGACY_CHUNK_REFERENCE
