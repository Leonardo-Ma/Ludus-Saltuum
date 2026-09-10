class_name ChunkSaveData
extends Resource

@export var world_seed: int = 0
@export var generation_version: int = 1
@export var active_chunk_keys: Array[int] = []
@export var next_chunk_key: int = 0
@export var scored_chunk_keys: Dictionary[int, bool] = { }
## Which scene was picked for each active chunk_key at generation time
@export var chunk_key_to_scene_uid: Dictionary[int, String] = { }
@export var chunk_selector_state: Dictionary = { }
