## Logic for selecting next procedural level based on constraints
class_name ChunkSelector
extends RefCounted

const MAX_VERTICAL_DEVIATION: float = 300.0
const MIN_VERTICAL_DEVIATION: float = -40.0
const SKILL_UNLOCK_SCORE_STEP: int = 50
const MIN_CHUNKS_BETWEEN_SKILLS: int = 5

var _rng: RandomNumberGenerator
var _all_chunks: Array[ChunkData]
var _recent_chunk_paths: Array[String] = []
var _chunks_since_turn: int = 5
var _last_skill_score_threshold: int = 0
var _chunks_since_skill_unlock: int = MIN_CHUNKS_BETWEEN_SKILLS


func _init(rng: RandomNumberGenerator, all_chunks: Array[ChunkData]) -> void:
	_rng = rng
	_all_chunks = all_chunks


func reset() -> void:
	_recent_chunk_paths.clear()
	_chunks_since_turn = 5
	_chunks_since_skill_unlock = MIN_CHUNKS_BETWEEN_SKILLS
	_last_skill_score_threshold = 0


func select_chunk_data(
	target_transform: Transform3D,
	unlocked_ids: Array[StringName],
	current_score: int,
	required_features: Array[ChunkFeature.Feature] = [],
) -> ChunkData:
	var current_y: float = target_transform.origin.y

	# Only force unlock when there are skills the player doesn't yet have
	var has_unlockable_skill: bool = _all_chunks.any(
		func(d: ChunkData) -> bool: return d.unlocks_skill_id != &"" and not unlocked_ids.has(d.unlocks_skill_id)
	)
	var force_skill_unlock: bool = (
		has_unlockable_skill
		and current_score >= _last_skill_score_threshold + SKILL_UNLOCK_SCORE_STEP
		and _chunks_since_skill_unlock >= MIN_CHUNKS_BETWEEN_SKILLS
	)

	var valid_pool: Array[ChunkData] = []
	var strict_pool: Array[ChunkData] = []

	print("\n==================== Chunk Selection Debug ====================")
	print("Target Y: ", current_y, " | Chunks since turn: ", _chunks_since_turn, " | Last skill score unlock: ", _last_skill_score_threshold)
	print("Force skill unlock: ", force_skill_unlock)
	print("Recent paths: ", _recent_chunk_paths)

	for data: ChunkData in _all_chunks:
		# --------------- skill unlock filtering ---------------
		if data.unlocks_skill_id != &"":
			if not force_skill_unlock:
				continue
			# Only re-offer if player still doesn't have it (allows re-spawning missed unlocks)
			if unlocked_ids.has(data.unlocks_skill_id):
				continue
		else:
			if force_skill_unlock:
				continue
		# --------------- tag filtering ---------------
		if not required_features.is_empty():
			var missing_feature: bool = required_features.any(func(tag: StringName) -> bool: return not data.tags.has(tag))
			if missing_feature:
				continue
		# --------------- required skills check ---------------
		var missing: bool = data.required_skill_ids.any(func(id: StringName) -> bool: return not unlocked_ids.has(id))
		if missing:
			continue

		# Prevent back-to-back turns
		if data.is_turn and _chunks_since_turn < 5:
			continue

		valid_pool.push_back(data)

		# Prevent level from going too high or too low
		if current_y + data.height_shift > MAX_VERTICAL_DEVIATION and data.height_shift > 0:
			continue
		if current_y + data.height_shift < MIN_VERTICAL_DEVIATION and data.height_shift < 0:
			continue

		strict_pool.push_back(data)

	print("Pool sizes → valid: %d, strict: %d, total available: %d" % [valid_pool.size(), strict_pool.size(), _all_chunks.size()])

	# Soft fallbacks
	if not strict_pool.is_empty():
		print("  → Using STRICT pool")
		valid_pool = strict_pool
	elif valid_pool.is_empty():
		print("  → EMERGENCY FALLBACK: using all basic chunks")
		valid_pool = _all_chunks.filter(func(d: ChunkData) -> bool: return d.unlocks_skill_id == &"")
		# If everything fails
		if valid_pool.is_empty():
			valid_pool = _all_chunks
	else:
		print("  → Using BASIC valid pool (some chunks may violate vertical/AABB)")

	# Avoid recent chunks
	var non_recent: Array[ChunkData] = valid_pool.filter(func(d: ChunkData) -> bool: return not d.scene_path in _recent_chunk_paths)
	if not non_recent.is_empty():
		print("  → Filtered out recent chunks, %d remain" % non_recent.size())
		valid_pool = non_recent
	else:
		print("  → WARNING: All valid chunks were recent! Relaxing filter to exclude only last chunk")
		var non_last: Array[ChunkData] = valid_pool.filter(
			func(d: ChunkData) -> bool: return _recent_chunk_paths.is_empty() or d.scene_path != _recent_chunk_paths.back()
		)
		if not non_last.is_empty():
			valid_pool = non_last

	var chosen: ChunkData = valid_pool[_rng.randi_range(0, valid_pool.size() - 1)]

	if chosen.unlocks_skill_id != &"":
		_chunks_since_skill_unlock = 0
		_last_skill_score_threshold += SKILL_UNLOCK_SCORE_STEP
	else:
		_chunks_since_skill_unlock += 1

	print("  ✓ SELECTED: [%s] (is_turn: %s, height_shift: %.1f)" % [chosen.scene_path.get_file(), chosen.is_turn, chosen.height_shift])
	print("====================================================\n")

	if chosen.is_turn:
		_chunks_since_turn = 0
	else:
		_chunks_since_turn += 1

	_recent_chunk_paths.push_back(chosen.scene_path)
	if _recent_chunk_paths.size() > 5:
		_recent_chunk_paths.pop_front()

	return chosen


func get_save_state() -> Dictionary:
	return {
		"recent_chunk_paths": _recent_chunk_paths.duplicate(),
		"chunks_since_turn": _chunks_since_turn,
		"chunks_since_skill_unlock": _chunks_since_skill_unlock,
		"last_skill_score_threshold": _last_skill_score_threshold,
		"rng_state": _rng.state,
	}


func load_save_state(state: Dictionary) -> void:
	_recent_chunk_paths = state.get("recent_chunk_paths", []).duplicate()
	_chunks_since_turn = state.get("chunks_since_turn", 5)
	_chunks_since_skill_unlock = state.get("chunks_since_skill_unlock", MIN_CHUNKS_BETWEEN_SKILLS)
	_last_skill_score_threshold = state.get("last_skill_score_threshold", 0)
	if state.has("rng_state"):
		_rng.state = state["rng_state"]
