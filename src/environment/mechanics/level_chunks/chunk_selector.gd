class_name ChunkSelector
extends RefCounted

## Logic for selecting next procedural level based on constraints

signal selection_made(
	chunk_seed: int,
	score: int,
	force_skill_unlock: bool,
	catalog_count: int,
	eligible_count: int,
	scheduled_count: int,
	turn_spaced_count: int,
	unseen_count: int,
	final_count: int,
)
signal selection_history_reset

const SKILL_UNLOCK_SCORE_STEP: int = 50
const MIN_CHUNKS_BETWEEN_SKILLS: int = 5
const TURN_COOLDOWN_CHUNKS: int = 5
const RECENT_CHUNK_HISTORY_SIZE: int = 15
const LEAST_RECENT_PICK_COUNT: int = 2

var _all_chunks: Array[ChunkData]
var _recent_chunk_scene_uids: Array[String] = []
## One entry per generated scene, ordered by last pick from oldest to newest
var _chunk_scene_recency: Array[String] = []
var _chunks_since_turn: int = TURN_COOLDOWN_CHUNKS
var _last_skill_score_threshold: int = 0
var _chunks_since_skill_unlock: int = MIN_CHUNKS_BETWEEN_SKILLS


func _init(all_chunks: Array[ChunkData]) -> void:
	_all_chunks = all_chunks


func reset() -> void:
	_recent_chunk_scene_uids.clear()
	_chunk_scene_recency.clear()
	_chunks_since_turn = TURN_COOLDOWN_CHUNKS
	_chunks_since_skill_unlock = MIN_CHUNKS_BETWEEN_SKILLS
	_last_skill_score_threshold = 0
	selection_history_reset.emit()


## Returns null and preserves history if no chunk meets skill, score, and feature requirements
## Relaxes recent history first, then turn spacing, then skill unlock scheduling
## Final selection is deterministic from chunk_seed
func select_deterministic_chunk_data(
	chunk_seed: int,
	unlocked_skills: Array[SkillDefinition],
	current_score: int,
	required_features: Array[ChunkFeature.Feature] = [],
) -> ChunkData:
	var valid_pool: Array[ChunkData] = _all_chunks.filter(
		func(data: ChunkData) -> bool:
			return (
				_passes_required_skill_filter(data, unlocked_skills) and _passes_min_score_filter(data, current_score)
				and _passes_feature_filter(data, required_features)
			),
	)
	if valid_pool.is_empty():
		return null
	var eligible_count: int = valid_pool.size()

	# Only force unlock when there are skills the player doesn't yet have
	var has_unlockable_skill: bool = valid_pool.any(
		func(data: ChunkData) -> bool:
			return data.unlocks_skill != null and not unlocked_skills.has(data.unlocks_skill),
	)
	var force_skill_unlock: bool = (
		has_unlockable_skill and current_score >= _last_skill_score_threshold + SKILL_UNLOCK_SCORE_STEP
		and _chunks_since_skill_unlock >= MIN_CHUNKS_BETWEEN_SKILLS
	)

	var scheduled_pool: Array[ChunkData] = valid_pool.filter(
		func(data: ChunkData) -> bool:
			return _passes_skill_unlock_filter(data, unlocked_skills, force_skill_unlock),
	)
	if not scheduled_pool.is_empty():
		valid_pool = scheduled_pool

	var turn_spaced_pool: Array[ChunkData] = valid_pool.filter(_passes_turn_filter)
	if not turn_spaced_pool.is_empty():
		valid_pool = turn_spaced_pool

	# Avoid recent chunks
	var unseen: Array[ChunkData] = _get_unseen_chunks(valid_pool)
	valid_pool = unseen if not unseen.is_empty() else _get_least_recent_chunks(valid_pool)

	var pick_rng: RandomNumberGenerator = RandomNumberGenerator.new()
	pick_rng.seed = chunk_seed
	var chosen: ChunkData = valid_pool[pick_rng.randi_range(0, valid_pool.size() - 1)]
	if selection_made.has_connections():
		selection_made.emit(
			chunk_seed,
			current_score,
			force_skill_unlock,
			_all_chunks.size(),
			eligible_count,
			scheduled_pool.size(),
			turn_spaced_pool.size(),
			unseen.size(),
			valid_pool.size(),
		)

	if chosen.unlocks_skill != null and not unlocked_skills.has(chosen.unlocks_skill):
		_chunks_since_skill_unlock = 0
		if current_score >= _last_skill_score_threshold + SKILL_UNLOCK_SCORE_STEP:
			_last_skill_score_threshold += SKILL_UNLOCK_SCORE_STEP
	else:
		_chunks_since_skill_unlock += 1

	if chosen.is_turn:
		_chunks_since_turn = 0
	else:
		_chunks_since_turn += 1

	_record_scene_recency(chosen.scene_uid)
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
	# Prefer spacing between turns
	return not data.is_turn or _chunks_since_turn >= TURN_COOLDOWN_CHUNKS


func _get_unseen_chunks(valid_pool: Array[ChunkData]) -> Array[ChunkData]:
	return valid_pool.filter(
		func(data: ChunkData) -> bool:
			return not _chunk_scene_recency.has(data.scene_uid),
	)


func _get_least_recent_chunks(valid_pool: Array[ChunkData]) -> Array[ChunkData]:
	var chunks_by_uid: Dictionary[String, ChunkData] = { }
	for data: ChunkData in valid_pool:
		chunks_by_uid[data.scene_uid] = data
	# Leave newest eligible scene out whenever another scene is available.
	var pick_count: int = clampi(chunks_by_uid.size() - 1, 1, LEAST_RECENT_PICK_COUNT)
	var oldest: Array[ChunkData] = []
	for scene_uid: String in _chunk_scene_recency:
		if chunks_by_uid.has(scene_uid):
			oldest.append(chunks_by_uid[scene_uid])
			if oldest.size() == pick_count:
				break
	return oldest


func _passes_min_score_filter(data: ChunkData, current_score: int) -> bool:
	return current_score >= data.min_score
#endregion


func _record_scene_recency(scene_uid: String) -> void:
	_chunk_scene_recency.erase(scene_uid)
	_chunk_scene_recency.append(scene_uid)


#region Save and Load
func get_save_state() -> Dictionary:
	return {
		"recent_chunk_scene_uids": _recent_chunk_scene_uids.duplicate(),
		"chunk_scene_recency": _chunk_scene_recency.duplicate(),
		"chunks_since_turn": _chunks_since_turn,
		"chunks_since_skill_unlock": _chunks_since_skill_unlock,
		"last_skill_score_threshold": _last_skill_score_threshold,
	}


func load_save_state(state: Dictionary) -> void:
	_recent_chunk_scene_uids.assign(state.get("recent_chunk_scene_uids", []))
	var saved_recency: Array = state.get("chunk_scene_recency", _recent_chunk_scene_uids)
	var catalog_uids: Array[String] = []
	for data: ChunkData in _all_chunks:
		catalog_uids.append(data.scene_uid)
	_chunk_scene_recency.clear()
	for scene_uid: String in saved_recency:
		if catalog_uids.has(scene_uid):
			_record_scene_recency(scene_uid)
	_chunks_since_turn = state.get("chunks_since_turn", TURN_COOLDOWN_CHUNKS)
	_chunks_since_skill_unlock = state.get("chunks_since_skill_unlock", MIN_CHUNKS_BETWEEN_SKILLS)
	_last_skill_score_threshold = state.get("last_skill_score_threshold", 0)
	selection_history_reset.emit()


static func is_valid_save_state(state: Dictionary) -> bool:
	for key: String in ["recent_chunk_scene_uids", "chunk_scene_recency"]:
		var scene_uids: Variant = state.get(key, [])
		if not (scene_uids is Array):
			return false
		for uid: Variant in scene_uids:
			if not (uid is String):
				return false
	for key: String in ["chunks_since_turn", "chunks_since_skill_unlock", "last_skill_score_threshold"]:
		var value: Variant = state.get(key, 0)
		if not (value is int) or value < 0:
			return false
	return true
#endregion
