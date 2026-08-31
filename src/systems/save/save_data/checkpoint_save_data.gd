class_name CheckpointSaveData
extends Resource

## chunk index -1 = world/global checkpoint
## bigger than 0, relateive to an active chunk
@export var checkpoint_chunk_index: int = -1

## Checkpoint transform relative to its chunk's origin at save time
@export var checkpoint_local_transform: Transform3D = Transform3D.IDENTITY

@export var has_checkpoint_position: bool = false
