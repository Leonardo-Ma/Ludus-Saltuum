# BUG TODO Improve this garbage
extends Node

## Manages object pooling, async loading, and sequential connecting of procedural level chunks

signal level_loaded()

signal chunk_recycled(recycled_chunk: LevelChunk)

const CHUNK_CATALOG: ChunkCatalog = preload("uid://dwe2glcvgdfgs") # chunk_catalog.tres

## Version of current implementation, MUST be incremented if new version no longer compatible
const GENERATION_VERSION: int = 1

const CHUNK_SPAWN_AMOUNT: int = 10
const CHUNK_INDEX_THAT_TRIGGERS_RECYCLING: int = 4

const LEVEL_COMPLETE_SOUNDS: Array[AudioStream] = [
	preload("uid://wsw31trreg3k"), # chequered_ink/brass_level_complete.wav
	preload("uid://c1auaooli8ysa"), # chequered_ink/grand_piano_level_complete.wav
	preload("uid://mihwryxscya7"), # chequered_ink/harpsichord_level_complete.wav
	preload("uid://b5ebce6j3jc7o"), # chequered_ink/music_box_level_complete.wav
	preload("uid://cmtn3755bxxon"), # chequered_ink/sitar_level_complete.wav
	preload("uid://bkvgbgxainyo1"), # chequered_ink/steel_drums_level_complete.wav
	preload("uid://d4kb4jp777v37"), # chequered_ink/synth_bass_level_complete.wav
	preload("uid://dl6cgw48oqc0y"), # chequered_ink/vibraphone_level_complete.wav
	preload("uid://b0bvycxcrnugp"), # chequered_ink/xylophone_level_complete.wa
]

const SKIP_LEVEL_RESPAWN_DELAY: float = 1.0

var procedural_seed: int = 0

var _pending_new_game_seed: int = 0

var _all_chunks: Array[ChunkData] = []
var _active_chunks: Array[LevelChunk] = []

var _player: PlayerEntity
var _chunk_container: Node3D

var _chunk_selector: ChunkSelector
var _chunk_exit_connections: Dictionary = { }

var _current_chunk_index: int = 0
var _next_chunk_key: int = 0
## Persisted selection outcome per chunk_key, entries pruned once a chunk is permanently recycled
var _chunk_key_to_scene_uid: Dictionary[int, String] = { }


func _ready() -> void:
	@warning_ignore("assert_always_true")
	assert(
		CHUNK_SPAWN_AMOUNT > CHUNK_INDEX_THAT_TRIGGERS_RECYCLING,
		"CHUNK_SPAWN_AMOUNT (%d) must be > CHUNK_INDEX_THAT_TRIGGERS_RECYCLING (%d)" % [CHUNK_SPAWN_AMOUNT, CHUNK_INDEX_THAT_TRIGGERS_RECYCLING],
	)

	_load_chunk_metadata_from_catalog()

	# TODO Double check
	set_procedural_seed(procedural_seed)


#region Level State
## Try to fetch the global seed, else random
func set_procedural_seed(value: int) -> void:
	procedural_seed = value if value != 0 else Time.get_ticks_msec()


func get_procedural_seed() -> int:
	return procedural_seed


func stage_new_game_seed(seed_value: int) -> void:
	_pending_new_game_seed = seed_value


func initialize_new_save_data() -> void:
	clear_level()
	_chunk_selector.reset()
	_next_chunk_key = 0
	_chunk_key_to_scene_uid.clear()
	set_procedural_seed(_pending_new_game_seed)
	_pending_new_game_seed = 0


func _load_chunk_metadata_from_catalog() -> void:
	assert(CHUNK_CATALOG != null, "Chunk catalog missing in " + name)

	for scene: PackedScene in CHUNK_CATALOG.chunks:
		var chunk: LevelChunk = scene.instantiate() as LevelChunk
		assert(chunk != null, "Catalog scene is not a LevelChunk in " + name)

		var checkpoints: Array[Node] = chunk.find_children("*", "Checkpoint", true, false)
		var data: ChunkData = ChunkData.new()

		data.has_checkpoint = not checkpoints.is_empty()

		var entrance_trigger: Node3D = chunk.get_node("%EntranceTrigger")
		var exit_trigger: Node3D = chunk.get_node("%ExitTrigger")

		data.height_shift = exit_trigger.position.y - entrance_trigger.position.y
		data.entrance_transform = chunk.transform.affine_inverse() * entrance_trigger.transform

		var in_z: Vector3 = entrance_trigger.transform.basis.z.normalized()
		var out_z: Vector3 = exit_trigger.transform.basis.z.normalized()
		data.is_turn = in_z.angle_to(out_z) > 0.1

		data.scene_path = scene.resource_path

		var resource_uid: int = ResourceLoader.get_resource_uid(data.scene_path)
		assert(resource_uid != ResourceUID.INVALID_ID, "ChunkManager: chunk scene has no UID in " + data.scene_path)
		data.scene_uid = ResourceUID.id_to_text(resource_uid)

		data.features = chunk.features.duplicate()
		data.required_skill = chunk.required_skill.duplicate()
		data.unlocks_skill = chunk.unlocks_skill
		data.score_multiplier = chunk.score_multiplier
		data.min_score = chunk.min_score
		data.difficulty_points = _get_difficulty_points(chunk, data)
		data.skill_points = _count_required_skills(data)

		_all_chunks.push_back(data)

		ResourceLoader.load_threaded_request(data.scene_path)

		chunk.free()

	var has_baseline_route: bool = _all_chunks.any(
		func(data: ChunkData) -> bool:
			return data.required_skill.is_empty() and data.min_score <= 0 and data.unlocks_skill == null,
	)
	if not has_baseline_route:
		get_tree().quit(1)
		assert(false, "Chunk catalog needs a regular route available at zero score without skills in " + name)
		return

	_chunk_selector = ChunkSelector.new(_all_chunks)


func get_next_chunk_key() -> int:
	return _next_chunk_key


func get_chunk_selector() -> ChunkSelector:
	return _chunk_selector


func get_chunk_scene_uid(chunk_key: int) -> String:
	assert(_chunk_key_to_scene_uid.has(chunk_key), "ChunkManager: no persisted scene uid for active chunk_key %d" % chunk_key)
	return _chunk_key_to_scene_uid[chunk_key]


func register_chunk_container(container: Node3D) -> void:
	assert(_chunk_container == null or _chunk_container == container, "Multiple chunk containers registered in " + name)
	_chunk_container = container


func unregister_chunk_container(container: Node3D) -> void:
	if _chunk_container == container:
		_chunk_container = null


func get_chunk_by_key(chunk_key: int) -> LevelChunk:
	for chunk: LevelChunk in _active_chunks:
		if chunk.chunk_key == chunk_key:
			return chunk
	return null


func reset_level_state() -> void:
	clear_level()
	_chunk_selector.reset()
	_next_chunk_key = 0
	_chunk_key_to_scene_uid.clear()
	set_procedural_seed(_pending_new_game_seed)
	_pending_new_game_seed = 0


## Validates saved route and stages persisted picks outside scene tree without filtering or RNG
func prepare_saved_chunks(data: ChunkSaveData) -> Array[LevelChunk]:
	if (
		not is_instance_valid(_chunk_container) or not _chunk_container.is_inside_tree() or data.generation_version != GENERATION_VERSION
		or data.active_chunk_keys.is_empty() or not ChunkSelector.is_valid_save_state(data.chunk_selector_state)
	):
		return []
	if data.has_first_chunk_transform:
		var determinant: float = data.first_chunk_transform.basis.determinant()
		if not data.first_chunk_transform.is_finite() or not is_finite(determinant) or is_zero_approx(determinant):
			return []

	var catalog_entries: Dictionary[int, ChunkData] = { }
	var previous_key: int = -1
	for chunk_key: int in data.active_chunk_keys:
		if chunk_key <= previous_key or chunk_key >= data.next_chunk_key:
			return []
		var entry: ChunkData = get_chunk_data_by_uid(data.chunk_key_to_scene_uid.get(chunk_key, ""))
		if entry == null:
			return []
		catalog_entries[chunk_key] = entry
		previous_key = chunk_key
	# Route needs an unscored chunk for restore to select as current
	if data.scored_chunk_keys.has(previous_key):
		return []
	for chunk_key: int in data.scored_chunk_keys:
		if not catalog_entries.has(chunk_key):
			return []

	var chunks: Array[LevelChunk] = []
	for chunk_key: int in data.active_chunk_keys:
		var chunk: LevelChunk = _instantiate_chunk_data(catalog_entries[chunk_key])
		if chunk == null:
			for prepared_chunk: LevelChunk in chunks:
				prepared_chunk.queue_free()
			return []
		chunk.chunk_key = chunk_key
		chunk.is_scored = data.scored_chunk_keys.has(chunk_key)
		_prepare_chunk_entities(chunk, data.world_seed)
		chunks.append(chunk)
	if not WorldSaveController.has_valid_entity_ids(chunks, _chunk_container):
		for chunk: LevelChunk in chunks:
			chunk.queue_free()
		return []
	return chunks


## Replaces active chunks with persisted ones, emits level_loaded when done
func restore_level(data: ChunkSaveData, chunks: Array[LevelChunk], player: PlayerEntity) -> void:
	clear_level()
	procedural_seed = data.world_seed
	_chunk_key_to_scene_uid = data.chunk_key_to_scene_uid.duplicate()
	_player = player
	_chunk_selector.load_save_state(data.chunk_selector_state)
	_next_chunk_key = data.next_chunk_key

	var next_spawn_transform: Transform3D = Transform3D()

	for chunk: LevelChunk in chunks:
		_chunk_container.add_child(chunk)
		if _active_chunks.is_empty() and data.has_first_chunk_transform:
			chunk.global_transform = data.first_chunk_transform
		else:
			_align_chunk_to_transform(chunk, next_spawn_transform)
		_activate_chunk(chunk)
		next_spawn_transform = chunk.exit_trigger.global_transform

	for chunk: LevelChunk in _active_chunks:
		if not chunk.is_scored:
			break
		_current_chunk_index += 1

	level_loaded.emit()

#endregion


## Load chunks to be kept in memory, save them in active chunks
func initialize_level() -> void:
	_player = get_tree().get_first_node_in_group(Groups.PLAYERS)
	assert(_player != null, "No player found for " + name)
	assert(is_instance_valid(_chunk_container) and _chunk_container.is_inside_tree(), "Chunk container missing in " + name)
	assert(_all_chunks.size() > 0, "No chunks available in LevelManager AutoLoad " + self.name)
	clear_level()

	var next_spawn_transform: Transform3D = Transform3D()

	for i: int in range(CHUNK_SPAWN_AMOUNT):
		var chunk_instance: LevelChunk = _append_generated_chunk(next_spawn_transform)
		if chunk_instance == null:
			return
		next_spawn_transform = chunk_instance.exit_trigger.global_transform

	level_loaded.emit()


## Reset pool when the reload or exit
func clear_level() -> void:
	for chunk: LevelChunk in _active_chunks:
		if is_instance_valid(chunk):
			_pool_chunk(chunk)
			var parent_world: Node = chunk.get_parent()
			if parent_world != null:
				parent_world.remove_child(chunk)
	_active_chunks.clear()
	_current_chunk_index = 0
	if _chunk_selector:
		_chunk_selector.reset()


## Triggers by exit trigger world collision boundary
func recycle_oldest_chunk() -> void:
	assert(_active_chunks.size() > 1, "Cannot recycle route without a surviving chunk in " + name)

	var oldest: LevelChunk = _active_chunks.pop_front()

	chunk_recycled.emit(oldest)

	_current_chunk_index = maxi(_current_chunk_index - 1, 0)
	_pool_chunk(oldest)
	_chunk_container.remove_child(oldest)
	_chunk_key_to_scene_uid.erase(oldest.chunk_key)

	var newest: LevelChunk = _active_chunks.back()
	var target_transform: Transform3D = newest.exit_trigger.global_transform
	# Snap the new chunk to the exit trigger of the current newest
	var next_chunk: LevelChunk = _append_generated_chunk(target_transform)
	if next_chunk != null:
		WorldSaveController.apply_saved_entity_states(next_chunk)


func get_active_chunks() -> Array[LevelChunk]:
	return _active_chunks


func get_chunk_entrance_position(chunk_index: int) -> Vector3:
	assert(chunk_index >= 0 and chunk_index < _active_chunks.size(), "Chunk index out of range in " + name)
	return _active_chunks[chunk_index].entrance_trigger.global_position


# TODO This may be useless, in current approach always returns 0 0 0 also
func get_first_chunk_entrance_position() -> Vector3:
	print("Entrance empty? ", _active_chunks.is_empty())
	if _active_chunks.is_empty():
		return Vector3.ZERO
	print("Entrance position:", _active_chunks[0].entrance_trigger.global_position)
	return _active_chunks[0].entrance_trigger.global_position


## Skips current chunk: marks scored, teleports player to its exit
func skip_current_chunk() -> void:
	assert(_current_chunk_index >= 0 and _current_chunk_index < _active_chunks.size(), "ChunkManager: no valid current chunk to skip in " + name)
	var current_chunk: LevelChunk = _active_chunks[_current_chunk_index]

	# Mark as scored without giving score since skipped
	current_chunk.is_scored = true

	_on_chunk_exit_reached(_player, current_chunk)
	var target_transform: Transform3D = Transform3D(_player.global_basis.orthonormalized(), current_chunk.exit_trigger.global_position)

	# TODO Find better way than couple this
	var rider: VehicleRider = _player.get_node(^"%VehicleRider")
	assert(rider, "VehicleRider missing in " + _player.name)
	rider.exit_vehicle(_player.position)

	ControlledEntityEvents.request_respawn(SKIP_LEVEL_RESPAWN_DELAY, target_transform)


# TODO This may be best be an enum/dict in level_chunk?
func _get_difficulty_points(chunk: LevelChunk, data: ChunkData) -> int:
	match chunk.difficulty:
		LevelChunk.Difficulty.EASY:
			return 10
		LevelChunk.Difficulty.MEDIUM:
			return 30
		LevelChunk.Difficulty.HARD:
			return 50

	assert(false, "Difficulty not found for this level chunk " + data.scene_path)
	return 0


# TODO Double check this
func _count_required_skills(data: ChunkData) -> int:
	return data.required_skill.size() * 2


func _get_chunk_data_by_path(path: String) -> ChunkData:
	for data: ChunkData in _all_chunks:
		if data.scene_path == path:
			return data
	return null


func _align_chunk_to_transform(chunk: LevelChunk, target_transform: Transform3D) -> void:
	var entrance_node: Node3D = chunk.entrance_trigger
	var rel_entrance: Transform3D = chunk.global_transform.affine_inverse() * entrance_node.global_transform
	chunk.global_transform = target_transform * rel_entrance.affine_inverse()


## Assigns deterministic collectible_id/enemy_id from chunk identity and authored placement
func _prepare_chunk_entities(chunk: LevelChunk, world_seed: int) -> void:
	for node: Node in chunk.find_children("*", "", true, false):
		if node is Collectible:
			var collectible: Collectible = node
			var placement_id: StringName = AuthoredEntityId.resolve(collectible, collectible.placement_id, chunk)
			if placement_id != &"":
				collectible.assign_procedural_id(ProceduralId.spawn_id(world_seed, chunk.chunk_key, placement_id))
		elif node is NPCEntity:
			var enemy: NPCEntity = node
			var placement_id: StringName = AuthoredEntityId.resolve(enemy, enemy.placement_id, chunk)
			if placement_id != &"":
				enemy.assign_procedural_id(ProceduralId.spawn_id(world_seed, chunk.chunk_key, placement_id))
		elif node is Checkpoint:
			# Checkpoints outside chunks have no parent LevelChunk
			var checkpoint: Checkpoint = node
			checkpoint.parent_chunk = chunk


func _append_generated_chunk(target_transform: Transform3D) -> LevelChunk:
	var chunk: LevelChunk = _generate_new_chunk()
	if chunk == null:
		return null
	_prepare_chunk_entities(chunk, procedural_seed)
	var valid_ids: bool = WorldSaveController.has_valid_entity_ids([chunk])
	if not valid_ids:
		chunk.queue_free()
		assert(false, "Persistent entity IDs must be nonempty and unique in " + chunk.name)
		get_tree().quit(1)
		return null
	# Chunks are currently instantiated fresh before they enter the tree
	_chunk_container.add_child(chunk)
	_align_chunk_to_transform(chunk, target_transform)
	_activate_chunk(chunk)
	return chunk


func _activate_chunk(chunk: LevelChunk) -> void:
	chunk.process_mode = Node.PROCESS_MODE_INHERIT
	chunk.visible = true
	_active_chunks.push_back(chunk)
	_setup_chunk_trigger(chunk)


func _setup_chunk_trigger(chunk: LevelChunk) -> void:
	var trigger: Area3D = chunk.exit_trigger
	_disconnect_chunk_trigger(chunk)
	var callable: Callable = _on_chunk_exit_reached.bind(chunk)
	_chunk_exit_connections[chunk.get_instance_id()] = callable
	trigger.body_entered.connect(callable)


func _on_chunk_exit_reached(body: Node3D, passed_chunk: LevelChunk) -> void:
	if not body.is_in_group(Groups.CONTROLLED):
		return

	var passed_index: int = _active_chunks.find(passed_chunk)
	if passed_index == -1:
		return

	# Skipped a level
	if passed_index > _current_chunk_index:
		var skipped_chunk: LevelChunk = _active_chunks[_current_chunk_index]
		var respawn_transform: Transform3D = skipped_chunk.entrance_trigger.global_transform
		respawn_transform.basis = respawn_transform.basis.orthonormalized()
		ControlledEntityEvents.request_respawn(SKIP_LEVEL_RESPAWN_DELAY, respawn_transform)
		return

	if passed_index < _current_chunk_index:
		return

	_current_chunk_index = passed_index + 1

	_player.status_manager.clear_temporary_statuses()

	if not passed_chunk.is_scored:
		passed_chunk.is_scored = true

		AudioManager.play_sound(LEVEL_COMPLETE_SOUNDS.pick_random() as AudioStream, AudioManager.SoundBus.SFX, body.global_position)

		var chunk_path: String = passed_chunk.scene_file_path
		for data: ChunkData in _all_chunks:
			if data.scene_path == chunk_path:
				var total_score: int = roundi((data.difficulty_points + data.skill_points) * data.score_multiplier)
				var economy: EconomyController = _player.get_node(^"%EconomyController")
				assert(economy, "EconomyController missing in " + _player.name)
				economy.add_score(total_score)
				break

	# Only start recycling after the configured start index
	if _active_chunks.size() > CHUNK_INDEX_THAT_TRIGGERS_RECYCLING and _active_chunks[CHUNK_INDEX_THAT_TRIGGERS_RECYCLING] == passed_chunk:
		_recycle_after_exit.call_deferred(passed_chunk)


func _recycle_after_exit(passed_chunk: LevelChunk) -> void:
	if _active_chunks.size() > CHUNK_INDEX_THAT_TRIGGERS_RECYCLING and _active_chunks[CHUNK_INDEX_THAT_TRIGGERS_RECYCLING] == passed_chunk:
		recycle_oldest_chunk()


# TODO This clearly doesn't pool >:( It may not be necessary yet, as levels are simple
func _pool_chunk(chunk: LevelChunk) -> void:
	_disconnect_chunk_trigger(chunk)
	chunk.entrance_trigger.set_deferred("monitoring", false)
	chunk.entrance_trigger.set_deferred("monitorable", false)
	chunk.is_scored = false
	chunk.queue_free()


func _disconnect_chunk_trigger(chunk: LevelChunk) -> void:
	var chunk_id: int = chunk.get_instance_id()
	if not _chunk_exit_connections.has(chunk_id):
		return

	var trigger: Area3D = chunk.exit_trigger
	var callable: Callable = _chunk_exit_connections[chunk_id]
	if trigger.body_entered.is_connected(callable):
		trigger.body_entered.disconnect(callable)
	_chunk_exit_connections.erase(chunk_id)


## Picks and instantiates a chunk never generated before, persists the pick for this chunk_key
func _generate_new_chunk() -> LevelChunk:
	var chunk_key: int = _next_chunk_key

	var skills: SkillsController = _player.get_node(^"%SkillsController")
	var economy: EconomyController = _player.get_node(^"%EconomyController")
	assert(skills and economy, "Chunk progression sources missing in " + _player.name)
	var unlocked_skills: Array[SkillDefinition] = skills.get_unlocked_skills()
	var chunk_seed: int = ProceduralId.chunk_seed(get_procedural_seed(), chunk_key)
	var chosen_data: ChunkData = _chunk_selector.select_deterministic_chunk_data(chunk_seed, unlocked_skills, economy.score)
	if chosen_data == null:
		get_tree().quit(1)
		assert(false, "No eligible chunk for key %d in %s" % [chunk_key, name])
		return null

	_next_chunk_key += 1
	_chunk_key_to_scene_uid[chunk_key] = chosen_data.scene_uid

	var chunk: LevelChunk = _instantiate_chunk_data(chosen_data)
	chunk.chunk_key = chunk_key

	return chunk


func _instantiate_chunk_data(chunk_data: ChunkData) -> LevelChunk:
	var load_status: ResourceLoader.ThreadLoadStatus = ResourceLoader.load_threaded_get_status(chunk_data.scene_path)
	var scene: PackedScene
	if load_status == ResourceLoader.THREAD_LOAD_LOADED:
		scene = ResourceLoader.load_threaded_get(chunk_data.scene_path) as PackedScene
	else:
		scene = load(chunk_data.scene_path) as PackedScene
	assert(scene != null, "ChunkManager: chunk scene not found '%s'" % chunk_data.scene_path)
	return scene.instantiate() as LevelChunk


func get_chunk_data_by_uid(uid: String) -> ChunkData:
	for data: ChunkData in _all_chunks:
		if data.scene_uid == uid:
			return data
	return null
