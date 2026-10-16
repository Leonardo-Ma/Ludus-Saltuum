## Verifies every save version in TEST_SAVES_DIR loads, migrates to current version and resolves all references
extends Node

const TEST_SAVES_DIR: String = "res://tests/saves/"
const SKILL_CATALOGUE: SkillCatalogue = preload("uid://6ygr0ieawafb") # skill_catalogue.tres


func _ready() -> void:
	if not OS.is_debug_build() or not owner.should_tests_be_executed:
		queue_free()
		return

	var version_directory: DirAccess = DirAccess.open(TEST_SAVES_DIR)
	assert(version_directory != null, "Save version directory missing in " + name)

	var saves: int = 0
	for file_name: String in version_directory.get_files():
		if file_name.ends_with(".tres"):
			_test_save_migration(TEST_SAVES_DIR + file_name)
			saves += 1

	assert(saves > 0, "No save found in " + name)
	print("Save version test completed (%d version)." % saves)
	self.queue_free()


func _test_save_migration(path: String) -> void:
	var data: SaveData = load(path) as SaveData
	assert(data != null, "Save failed to load: %s in %s" % [path, name])

	var migrated: bool = SaveManager._migrate(data)
	assert(migrated, "Save migration failed: %s in %s" % [path, name])
	assert(data.save_version == SaveManager.CURRENT_SAVE_VERSION, "Save not at current version: %s in %s" % [path, name])

	_test_player(data.player, path)
	_test_chunks(data.chunks, data.checkpoint, path)


func _test_player(player: PlayerSaveData, path: String) -> void:
	assert(player.unlocked_skills.is_empty(), "Legacy skill references left after migration: %s in %s" % [path, name])

	for skill_id: StringName in player.unlocked_skill_ids:
		assert(SKILL_CATALOGUE.find_by_id(skill_id) != null, "Unknown skill id '%s': %s in %s" % [skill_id, path, name])

	for egg: EasterEgg.Name in player.found_easter_egg_names:
		assert(egg != EasterEgg.Name.UNDEFINED and EasterEgg.Name.values().has(egg), "Invalid easter egg %d: %s in %s" % [egg, path, name])


func _test_chunks(chunks: ChunkSaveData, checkpoint: CheckpointSaveData, path: String) -> void:
	assert(chunks.generation_version == ChunkManager.GENERATION_VERSION, "Generation version mismatch: %s in %s" % [path, name])
	assert(not chunks.active_chunk_keys.is_empty(), "No active chunks: %s in %s" % [path, name])

	for chunk_key: int in chunks.active_chunk_keys:
		assert(chunk_key < chunks.next_chunk_key, "Chunk key %d >= next_chunk_key: %s in %s" % [chunk_key, path, name])
		assert(chunks.chunk_key_to_scene_uid.has(chunk_key), "No scene uid for chunk key %d: %s in %s" % [chunk_key, path, name])
		var scene_uid: String = chunks.chunk_key_to_scene_uid[chunk_key]
		assert(ChunkManager._get_chunk_data_by_uid(scene_uid) != null, "Unknown chunk scene uid '%s': %s in %s" % [scene_uid, path, name])

	for chunk_key: int in chunks.scored_chunk_keys:
		assert(chunks.active_chunk_keys.has(chunk_key), "Scored chunk key %d not active: %s in %s" % [chunk_key, path, name])

	assert(
		not checkpoint.has_checkpoint_position or checkpoint.checkpoint_chunk_index < chunks.active_chunk_keys.size(),
		"Checkpoint chunk index out of range: %s in %s" % [path, name],
	)
