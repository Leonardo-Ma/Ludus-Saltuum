extends SaveController

## Persists ChunkManager state, restores chunks on load, regenerates level on new game


func _child_ready() -> void:
	SaveManager.load_requested.connect(_on_load_requested)
	SaveManager.reset_finished.connect(ChunkManager.initialize_level)


func _on_save_requested(data: SaveData) -> void:
	build_save_data(data.chunks)


func initialize_new_save_data() -> void:
	ChunkManager.reset_level_state()


func build_save_data(data: ChunkSaveData) -> void:
	data.world_seed = ChunkManager.get_procedural_seed()
	data.generation_version = ChunkManager.GENERATION_VERSION

	var keys: Array[int] = []
	var scored: Dictionary[int, bool] = { }
	var uid_map: Dictionary[int, String] = { }
	for chunk: LevelChunk in ChunkManager.get_active_chunks():
		keys.push_back(chunk.chunk_key)
		if chunk.is_scored:
			scored[chunk.chunk_key] = true
		uid_map[chunk.chunk_key] = ChunkManager.get_chunk_scene_uid(chunk.chunk_key)
	data.active_chunk_keys = keys
	data.next_chunk_key = ChunkManager.get_next_chunk_key()
	data.scored_chunk_keys = scored
	data.chunk_key_to_scene_uid = uid_map
	data.chunk_selector_state = ChunkManager.get_chunk_selector_state()


func apply_save_data(data: ChunkSaveData) -> void:
	assert(
		data.generation_version == ChunkManager.GENERATION_VERSION,
		"ChunkSaveController: unsupported generation version %d in %s" % [data.generation_version, name],
	)
	ChunkManager.restore_level(
		data.world_seed,
		data.active_chunk_keys,
		data.next_chunk_key,
		data.scored_chunk_keys,
		data.chunk_key_to_scene_uid,
		data.chunk_selector_state,
	)


func _on_load_requested(data: SaveData) -> void:
	apply_save_data(data.chunks)
