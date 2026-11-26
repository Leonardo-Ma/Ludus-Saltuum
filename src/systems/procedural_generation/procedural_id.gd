## Derives chunk seeds and persistent identities for regenerated placements
class_name ProceduralId
extends RefCounted


static func chunk_seed(world_seed: int, chunk_key: int) -> int:
	return hash(PackedInt64Array([world_seed, chunk_key]))


static func spawn_id(world_seed: int, chunk_key: int, placement_id: StringName) -> StringName:
	return StringName("%d:%d:%s" % [world_seed, chunk_key, placement_id])
