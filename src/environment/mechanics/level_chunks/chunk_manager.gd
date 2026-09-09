# TODO Rename to level_chunk_manager (same as autoload)
# BUG TODO Improve this garbage
## Manages object pooling, async loading, and sequential connecting of procedural level chunks
extends Node

signal level_loaded(checkpoint_data: CheckpointSaveData)

signal chunk_recycled(recycled_chunk: LevelChunk)

# BUG: TODO: Consider if there's better approach instead of hardcore path
# fmt:off
const CHUNK_DIRECTORIES: Array[String] = [
	"res://src/environment/levels/base_levels/",
	"res://src/environment/levels/skills/",
]
# fmt:on

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

var procedural_seed: int = 0

var _all_chunks: Array[ChunkData] = []
var _active_chunks: Array[LevelChunk] = []

var _player: PlayerEntity

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
	_load_chunk_metadata_from_disk()

	# TODO Double check
	set_procedural_seed(procedural_seed)

	SaveManager.save_requested.connect(
		func(data: SaveData) -> void:
			build_save_data(data.chunks),
	)
	SaveManager.load_requested.connect(_on_load_requested)
	SaveManager.reset_requested.connect(reset_save_data)
	SaveManager.reset_finished.connect(initialize_level)
	ControlledEntityEvents.player_finished_spawning.connect(_on_player_spawned)


## Try to fetch the global seed, else random
func set_procedural_seed(value: int) -> void:
	procedural_seed = value if value != 0 else Time.get_ticks_msec()


func get_procedural_seed() -> int:
	return procedural_seed

#region Saving and Loading
func build_save_data(data: ChunkSaveData) -> void:
	data.world_seed = get_procedural_seed()
	var keys: Array[int] = []
	var scored: Dictionary[int, bool] = { }
	var uid_map: Dictionary[int, String] = { }

	for chunk: LevelChunk in _active_chunks:
		keys.push_back(chunk.chunk_key)
		if chunk.has_meta("scored"):
			scored[chunk.chunk_key] = true
		assert(_chunk_key_to_scene_uid.has(chunk.chunk_key), "ChunkManager: no persisted scene uid for active chunk_key %d" % chunk.chunk_key)
		uid_map[chunk.chunk_key] = _chunk_key_to_scene_uid[chunk.chunk_key]

	data.active_chunk_keys = keys
	data.next_chunk_key = _next_chunk_key
	data.scored_chunk_keys = scored
	data.chunk_key_to_scene_uid = uid_map
	data.chunk_selector_state = _chunk_selector.get_save_state()


func apply_save_data(data: ChunkSaveData) -> void:
	set_procedural_seed(data.world_seed)
	_chunk_key_to_scene_uid = data.chunk_key_to_scene_uid.duplicate()
	_load_save_data(data.active_chunk_keys, data.next_chunk_key, data.scored_chunk_keys, data.chunk_selector_state)


func reset_save_data() -> void:
	clear_level()
	_chunk_selector.reset()
	_next_chunk_key = 0
	_chunk_key_to_scene_uid.clear()


func _load_save_data(active_chunk_keys: Array[int], saved_next_key: int, scored_keys: Dictionary[int, bool], selector_state: Dictionary) -> void:
	var parent_world: Node = get_tree().root.get_node("Main")

	clear_level()

	assert(_chunk_selector != null, "_load_save_data called before metadata was loaded")
	_chunk_selector.load_save_state(selector_state)
	assert(not active_chunk_keys.is_empty(), "Save contains no active chunks in " + name)

	_next_chunk_key = saved_next_key

	var next_spawn_transform: Transform3D = Transform3D()

	for chunk_key: int in active_chunk_keys:
		var chunk: LevelChunk = _instantiate_persisted_chunk(chunk_key)

		if chunk.get_parent() != null:
			chunk.get_parent().remove_child(chunk)
		parent_world.add_child(chunk)
		chunk.process_mode = Node.PROCESS_MODE_INHERIT
		chunk.visible = true

		_align_chunk_to_transform(chunk, next_spawn_transform)

		if scored_keys.has(chunk_key):
			chunk.set_meta("scored", true)

		_active_chunks.push_back(chunk)
		_setup_chunk_trigger(chunk)

		next_spawn_transform = chunk.exit_trigger.global_transform


func _load_chunk_metadata_from_disk() -> void:
	for dir_path: String in CHUNK_DIRECTORIES:
		var dir: DirAccess = DirAccess.open(dir_path)
		if dir:
			dir.list_dir_begin()
			var file_name: String = dir.get_next()
			while file_name != "":
				if not dir.current_is_dir():
					if file_name.ends_with(".tscn") or file_name.ends_with(".tscn.remap"):
						var clean_name: String = file_name.trim_suffix(".remap")
						var full_path: String = dir_path + clean_name

						# Sync load once at startup just to read the metadata/skills required.
						# Ideally, this metadata would be in a separate Resource (.tres) to avoid loading the full scene.
						var scene: PackedScene = load(full_path) as PackedScene
						if scene:
							var chunk: LevelChunk = scene.instantiate() as LevelChunk
							if chunk:
								var checkpoints: Array[Node] = chunk.find_children("*", "Checkpoint", true, false)
								var data: ChunkData = ChunkData.new()
								data.has_checkpoint = checkpoints.size() > 0

								# Chunk is never added to the tree (only metadata), so
								# @onready entrance_trigger/exit_trigger are never set. Need use get_node directly
								var entrance_trigger: Node3D = chunk.get_node("%EntranceTrigger")
								var exit_trigger: Node3D = chunk.get_node("%ExitTrigger")
								data.height_shift = exit_trigger.position.y - entrance_trigger.position.y
								data.entrance_transform = chunk.transform.affine_inverse() * entrance_trigger.transform
								var in_z: Vector3 = entrance_trigger.transform.basis.z.normalized()
								var out_z: Vector3 = exit_trigger.transform.basis.z.normalized()
								data.is_turn = in_z.angle_to(out_z) > 0.1

								data.scene_path = full_path
								var resource_uid: int = ResourceLoader.get_resource_uid(full_path)
								assert(resource_uid != ResourceUID.INVALID_ID, "ChunkManager: chunk scene has no UID in " + full_path)
								data.scene_uid = ResourceUID.id_to_text(resource_uid)
								data.features = chunk.features.duplicate()
								data.required_skill = chunk.required_skill.duplicate()
								data.unlocks_skill = chunk.unlocks_skill
								data.score_multiplier = chunk.score_multiplier

								data.difficulty_points = _get_difficulty_points(chunk, data)
								data.skill_points = _count_required_skills(data)

								_all_chunks.push_back(data)

								# Start async loading the scene so it's ready in memory when needed
								ResourceLoader.load_threaded_request(full_path)

								chunk.free()
				file_name = dir.get_next()
	assert(_all_chunks.size() > 0, "No valid LevelChunks found in directories.")
	_chunk_selector = ChunkSelector.new(_all_chunks)

#endregion

## Load chunks to be kept in memory, save them in active chunks
func initialize_level() -> void:
	_player = get_tree().get_first_node_in_group(Groups.PLAYERS)
	assert(_player != null, "No player found for " + name)
	var parent_world: Node = get_tree().root.get_node("Main")
	assert(_all_chunks.size() > 0, "No chunks available in LevelManager AutoLoad " + self.name)
	clear_level()

	var next_spawn_transform: Transform3D = Transform3D()

	for i: int in range(CHUNK_SPAWN_AMOUNT):
		var chunk_instance: LevelChunk = _generate_new_chunk(next_spawn_transform)

		# If chunk was pooled, it might already be in the tree, otherwise add it
		if chunk_instance.get_parent() != parent_world:
			if chunk_instance.get_parent() != null:
				chunk_instance.get_parent().remove_child(chunk_instance)
			parent_world.add_child(chunk_instance)

		chunk_instance.process_mode = Node.PROCESS_MODE_INHERIT
		chunk_instance.visible = true
		_align_chunk_to_transform(chunk_instance, next_spawn_transform)
		_active_chunks.push_back(chunk_instance)

		_setup_chunk_trigger(chunk_instance)

		next_spawn_transform = chunk_instance.get_node("%ExitTrigger").global_transform


## Reset pool when the reload or exit
func clear_level() -> void:
	for chunk: LevelChunk in _active_chunks:
		if is_instance_valid(chunk):
			_pool_chunk(chunk)
	_active_chunks.clear()
	_current_chunk_index = 0
	if _chunk_selector:
		_chunk_selector.reset()


## Triggers by exit trigger world collision boundary
func recycle_oldest_chunk() -> void:
	var parent_world: Node = get_tree().root.get_node("Main")
	assert(not _active_chunks.is_empty(), "Cannot recycle empty pool in " + name)

	var oldest: LevelChunk = _active_chunks.pop_front()

	chunk_recycled.emit(oldest)

	_current_chunk_index = maxi(_current_chunk_index - 1, 0)
	_pool_chunk(oldest)

	var newest: LevelChunk = _active_chunks.back()
	var target_transform: Transform3D = newest.get_node("%ExitTrigger").global_transform
	var next_chunk: LevelChunk = _generate_new_chunk(target_transform)

	if next_chunk.get_parent() != parent_world:
		if next_chunk.get_parent() != null:
			next_chunk.get_parent().remove_child(next_chunk)
		parent_world.add_child(next_chunk)

	# Snap the new chunk to the exit trigger of the current newest
	next_chunk.process_mode = Node.PROCESS_MODE_INHERIT
	next_chunk.visible = true
	_align_chunk_to_transform(next_chunk, target_transform)

	_active_chunks.push_back(next_chunk)
	_setup_chunk_trigger(next_chunk)


func get_active_chunks() -> Array[LevelChunk]:
	return _active_chunks


func get_chunk_entrance_position(chunk_index: int) -> Vector3:
	assert(chunk_index >= 0 and chunk_index < _active_chunks.size(), "Chunk index out of range in " + name)
	return (_active_chunks[chunk_index].get_node("%EntranceTrigger") as Node3D).global_position


# TODO This may be useless, in current approach always returns 0 0 0 also
func get_first_chunk_entrance_position() -> Vector3:
	print("Entrance empty? ", _active_chunks.is_empty())
	if _active_chunks.is_empty():
		return Vector3.ZERO
	print("Entrance position:", (_active_chunks[0].get_node("%EntranceTrigger") as Area3D).global_position)
	return (_active_chunks[0].get_node("%EntranceTrigger") as Area3D).global_position


## Skips current chunk: marks scored, teleports player to its exit
func skip_current_chunk(player: PlayerEntity) -> void:
	assert(_current_chunk_index >= 0 and _current_chunk_index < _active_chunks.size(), "LevelChunkManager: no valid current chunk to skip in " + name)
	var current_chunk: LevelChunk = _active_chunks[_current_chunk_index]
	# Mark as scored without giving score since skipped
	current_chunk.set_meta("scored", true)
	_on_chunk_exit_reached(player, current_chunk)
	var exit_trigger: Node3D = current_chunk.exit_trigger
	player.global_position = exit_trigger.global_position


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


func _on_player_spawned(player: PlayerEntity) -> void:
	_player = player
	initialize_level.call_deferred()


func _align_chunk_to_transform(chunk: LevelChunk, target_transform: Transform3D) -> void:
	var entrance_node: Node3D = chunk.entrance_trigger
	var rel_entrance: Transform3D = chunk.global_transform.affine_inverse() * entrance_node.global_transform
	chunk.global_transform = target_transform * rel_entrance.affine_inverse()
	_sync_chunk_spawn_ids(chunk)


## Assigns deterministic collectible_id/enemy_id from chunk_seed + traversal-order spawn_index
func _sync_chunk_spawn_ids(chunk: LevelChunk) -> void:
	var seed_value: int = ProceduralId.chunk_seed(get_procedural_seed(), chunk.chunk_key)
	var spawn_index: int = 0

	for node: Node in chunk.find_children("*", "", true, false):
		if node is Collectible:
			(node as Collectible).collectible_id = ProceduralId.spawn_id(seed_value, spawn_index)
			spawn_index += 1
		elif node.is_in_group(Groups.ENEMIES):
			(node as AggressiveEntity).enemy_id = ProceduralId.spawn_id(seed_value, spawn_index)
			spawn_index += 1
		elif node.is_in_group(Groups.PLAYERS):
			node.spawn_position = node.global_position


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
	if passed_index == -1 or passed_index < _current_chunk_index:
		return

	_current_chunk_index = passed_index + 1

	if not passed_chunk.has_meta("scored"):
		passed_chunk.set_meta("scored", true)
		SoundManager.play_sound(LEVEL_COMPLETE_SOUNDS.pick_random() as AudioStream, SoundManager.SoundCategory.SFX, body.global_position)
		var chunk_path: String = passed_chunk.scene_file_path
		for data: ChunkData in _all_chunks:
			if data.scene_path == chunk_path:
				var total_score: int = roundi((data.difficulty_points + data.skill_points) * data.score_multiplier)
				_player.economy_controller.add_score(total_score)
				break

	# Only start recycling after the configured start index
	if _active_chunks.size() > CHUNK_INDEX_THAT_TRIGGERS_RECYCLING and _active_chunks[CHUNK_INDEX_THAT_TRIGGERS_RECYCLING] == passed_chunk:
		recycle_oldest_chunk()


# TODO This clearly doesn't pool >:(
func _pool_chunk(chunk: LevelChunk) -> void:
	_disconnect_chunk_trigger(chunk)
	chunk.entrance_trigger.set_deferred("monitoring", false)
	chunk.entrance_trigger.set_deferred("monitorable", false)
	if chunk.has_meta("scored"):
		chunk.remove_meta("scored")
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
func _generate_new_chunk(target_transform: Transform3D) -> LevelChunk:
	var chunk_key: int = _next_chunk_key
	_next_chunk_key += 1

	var unlocked_skills: Array[SkillDefinition] = _player.skills_controller.get_unlocked_skills()
	var chunk_seed: int = ProceduralId.chunk_seed(get_procedural_seed(), chunk_key)
	var chosen_data: ChunkData = _chunk_selector.select_deterministic_chunk_data(
		target_transform,
		chunk_seed,
		unlocked_skills,
		_player.economy_controller.score,
	)
	_chunk_key_to_scene_uid[chunk_key] = chosen_data.scene_uid

	var chunk: LevelChunk = _instantiate_chunk_data(chosen_data)
	chunk.chunk_key = chunk_key

	return chunk


## Instantiates a chunk_key using its persisted pick, no filtering/RNG involved
func _instantiate_persisted_chunk(chunk_key: int) -> LevelChunk:
	assert(_chunk_key_to_scene_uid.has(chunk_key), "ChunkManager: no persisted scene uid for chunk_key %d" % chunk_key)
	var chunk_data: ChunkData = _get_chunk_data_by_uid(_chunk_key_to_scene_uid[chunk_key])
	assert(chunk_data != null, "ChunkManager: no chunk found for persisted uid at chunk_key %d" % chunk_key)
	var chunk: LevelChunk = _instantiate_chunk_data(chunk_data)
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


func _get_chunk_data_by_uid(uid: String) -> ChunkData:
	for data: ChunkData in _all_chunks:
		if data.scene_uid == uid:
			return data
	return null


func _on_load_requested(data: SaveData) -> void:
	apply_save_data(data.chunks)
	level_loaded.emit(data.checkpoint)
