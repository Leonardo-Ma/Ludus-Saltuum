## Logic for selecting next procedural level based on constraints
class_name ChunkSelector
extends RefCounted

const SKILL_UNLOCK_SCORE_STEP: int = 50
const MIN_CHUNKS_BETWEEN_SKILLS: int = 5
const TURN_COOLDOWN_CHUNKS: int = 5
const RECENT_CHUNK_HISTORY_SIZE: int = 15

var _all_chunks: Array[ChunkData]
var _recent_chunk_scene_uids: Array[String] = []
var _chunks_since_turn: int = TURN_COOLDOWN_CHUNKS
var _last_skill_score_threshold: int = 0
var _chunks_since_skill_unlock: int = MIN_CHUNKS_BETWEEN_SKILLS


func _init(all_chunks: Array[ChunkData]) -> void:
	_all_chunks = all_chunks


func reset() -> void:
	_recent_chunk_scene_uids.clear()
	_chunks_since_turn = TURN_COOLDOWN_CHUNKS
	_chunks_since_skill_unlock = MIN_CHUNKS_BETWEEN_SKILLS
	_last_skill_score_threshold = 0


## Filtering by runtime state produces the valid pool; final selection is deterministic from chunk_seed
func select_deterministic_chunk_data(
	target_transform: Transform3D,
	chunk_seed: int,
	unlocked_skills: Array[SkillDefinition],
	current_score: int,
	required_features: Array[ChunkFeature.Feature] = [],
) -> ChunkData:
	if not required_features.is_empty():
		var any_chunk_provides_features: bool = _all_chunks.any(
			func(data: ChunkData) -> bool:
				return required_features.all(
					func(feature: ChunkFeature.Feature) -> bool:
						return data.features.has(feature),
				),
		)
		assert(any_chunk_provides_features, "ChunkSelector: no chunk provides all required_features %s" % [required_features])

	var current_y: float = target_transform.origin.y

	# Only force unlock when there are skills the player doesn't yet have
	var has_unlockable_skill: bool = _all_chunks.any(
		func(data: ChunkData) -> bool:
			return data.unlocks_skill != null and not unlocked_skills.has(data.unlocks_skill),
	)
	var force_skill_unlock: bool = (
		has_unlockable_skill and current_score >= _last_skill_score_threshold + SKILL_UNLOCK_SCORE_STEP
		and _chunks_since_skill_unlock >= MIN_CHUNKS_BETWEEN_SKILLS
	)

	var valid_pool: Array[ChunkData] = []

	print("\n==================== Chunk Selection Debug ====================")
	print("Target Y: ", current_y, " | Chunks since turn: ", _chunks_since_turn, " | Last skill score unlock: ", _last_skill_score_threshold)
	print("Force skill unlock: ", force_skill_unlock)
	print("Recent paths: ", _recent_chunk_scene_uids)

	for data: ChunkData in _all_chunks:
		if not _passes_skill_unlock_filter(data, unlocked_skills, force_skill_unlock):
			continue

		if not _passes_feature_filter(data, required_features):
			continue

		if not _passes_required_skill_filter(data, unlocked_skills):
			continue

		if not _passes_turn_filter(data):
			continue

		valid_pool.push_back(data)

	print("Pool size: %d, total available: %d" % [valid_pool.size(), _all_chunks.size()])

	if valid_pool.is_empty():
		print("  → EMERGENCY FALLBACK: using all basic chunks")
		valid_pool = _all_chunks.filter(_is_basic_chunk)

		if valid_pool.is_empty():
			valid_pool = _all_chunks

	# Avoid recent chunks
	var non_recent: Array[ChunkData] = _filter_recent_chunks(valid_pool)

	if not non_recent.is_empty():
		print("  → Filtered out recent chunks, %d remain" % non_recent.size())
		valid_pool = non_recent
	else:
		print("  → WARNING: All valid chunks were recent! Relaxing filter to exclude only last chunk")
		var non_last: Array[ChunkData] = _filter_non_last_chunk(valid_pool)

		if not non_last.is_empty():
			valid_pool = non_last

	var pick_rng: RandomNumberGenerator = RandomNumberGenerator.new()
	pick_rng.seed = chunk_seed
	var chosen: ChunkData = valid_pool[pick_rng.randi_range(0, valid_pool.size() - 1)]

	if chosen.unlocks_skill != null:
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

	_recent_chunk_scene_uids.push_back(chosen.scene_uid)
	if _recent_chunk_scene_uids.size() > RECENT_CHUNK_HISTORY_SIZE:
		_recent_chunk_scene_uids.pop_front()

	return chosen

#region Filters
func _passes_skill_unlock_filter(data: ChunkData, unlocked_skills: Array[SkillDefinition], force_skill_unlock: bool) -> bool:
	# --------------- skill unlock filtering ---------------
	if data.unlocks_skill != null:
		if not force_skill_unlock:
			return false
		if unlocked_skills.has(data.unlocks_skill):
			return false
	else:
		if force_skill_unlock:
			return false

	return true


func _passes_feature_filter(data: ChunkData, required_features: Array[ChunkFeature.Feature]) -> bool:
	# --------------- tag filtering ---------------
	if required_features.is_empty():
		return true

	var missing_feature: bool = required_features.any(
		func(feature: ChunkFeature.Feature) -> bool:
			return not data.features.has(feature),
	)

	return not missing_feature


func _passes_required_skill_filter(data: ChunkData, unlocked_skills: Array[SkillDefinition]) -> bool:
	# --------------- required skills check ---------------
	var missing: bool = data.required_skill.any(
		func(skill: SkillDefinition) -> bool:
			return not unlocked_skills.has(skill),
	)

	return not missing


func _passes_turn_filter(data: ChunkData) -> bool:
	# Prevent back-to-back turns
	return not data.is_turn or _chunks_since_turn >= TURN_COOLDOWN_CHUNKS


func _is_basic_chunk(data: ChunkData) -> bool:
	return data.unlocks_skill == null


func _filter_recent_chunks(valid_pool: Array[ChunkData]) -> Array[ChunkData]:
	return valid_pool.filter(
		func(data: ChunkData) -> bool:
			return not data.scene_uid in _recent_chunk_scene_uids,
	)


func _filter_non_last_chunk(valid_pool: Array[ChunkData]) -> Array[ChunkData]:
	return valid_pool.filter(
		func(data: ChunkData) -> bool:
			return _recent_chunk_scene_uids.is_empty() or data.scene_uid != _recent_chunk_scene_uids.back(),
	)
#endregion

#region Save and Load
func get_save_state() -> Dictionary:
	return {
		"recent_chunk_scene_uids": _recent_chunk_scene_uids.duplicate(),
		"chunks_since_turn": _chunks_since_turn,
		"chunks_since_skill_unlock": _chunks_since_skill_unlock,
		"last_skill_score_threshold": _last_skill_score_threshold,
	}


func load_save_state(state: Dictionary) -> void:
	_recent_chunk_scene_uids = state.get("recent_chunk_scene_uids", []).duplicate()
	_chunks_since_turn = state.get("chunks_since_turn", TURN_COOLDOWN_CHUNKS)
	_chunks_since_skill_unlock = state.get("chunks_since_skill_unlock", MIN_CHUNKS_BETWEEN_SKILLS)
	_last_skill_score_threshold = state.get("last_skill_score_threshold", 0)
#endregion
