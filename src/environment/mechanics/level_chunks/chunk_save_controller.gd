extends SaveController

## Persists ChunkManager state and regenerates level on new game


func _child_ready() -> void:
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
	var active_chunks: Array[LevelChunk] = ChunkManager.get_active_chunks()
	data.has_first_chunk_transform = not active_chunks.is_empty()
	if data.has_first_chunk_transform:
		data.first_chunk_transform = active_chunks[0].global_transform
	for chunk: LevelChunk in active_chunks:
		keys.push_back(chunk.chunk_key)
		if chunk.is_scored:
			scored[chunk.chunk_key] = true
		uid_map[chunk.chunk_key] = ChunkManager.get_chunk_scene_uid(chunk.chunk_key)
	data.active_chunk_keys = keys
	data.next_chunk_key = ChunkManager.get_next_chunk_key()
	data.scored_chunk_keys = scored
	data.chunk_key_to_scene_uid = uid_map
	data.chunk_selector_state = ChunkManager.get_chunk_selector().get_save_state()
