class_name CheckpointSaveData
extends Resource

const WORLD_CHECKPOINT_INDEX: int = -1

## -1 for world checkpoints, 0 or greater for active chunk indices
@export var checkpoint_chunk_index: int = WORLD_CHECKPOINT_INDEX

## World transform for world checkpoints, relative to chunk origin otherwise
@export var checkpoint_local_transform: Transform3D = Transform3D.IDENTITY

@export var has_checkpoint_position: bool = false


static func is_valid_chunk_index(chunk_index: int, chunk_count: int) -> bool:
	return chunk_index == WORLD_CHECKPOINT_INDEX or (chunk_index >= 0 and chunk_index < chunk_count)
