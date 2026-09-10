## Deterministic seed/id derivation, world_seed + chunk_key reproduce identical chunk_seed and entity ids
class_name ProceduralId
extends RefCounted


static func chunk_seed(world_seed: int, chunk_key: int) -> int:
	return hash(PackedInt64Array([world_seed, chunk_key]))


static func spawn_id(seed_value: int, scene_local_path: NodePath) -> StringName:
	return StringName("%d:%s" % [seed_value, String(scene_local_path)])
