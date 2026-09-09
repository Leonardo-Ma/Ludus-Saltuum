## Deterministic seed/id derivation, world_seed + chunk_key reproduce identical chunk_seed and entity ids
class_name ProceduralId
extends RefCounted


static func chunk_seed(world_seed: int, chunk_key: int) -> int:
	return hash(PackedInt64Array([world_seed, chunk_key]))


static func spawn_id(seed_value: int, spawn_index: int) -> StringName:
	return StringName("%d:%d" % [seed_value, spawn_index])
