class_name CheckpointSaveData
extends Resource

## Scene file path of the chunk containing the checkpoint (e.g., "res://src/environment/levels/base_levels/chunk_01.tscn")
@export var checkpoint_chunk_scene_path: String = ""

## Checkpoint transform relative to its chunk's origin at save time
@export var checkpoint_local_transform: Transform3D = Transform3D.IDENTITY

@export var has_checkpoint_position: bool = false
