class_name ChunkDecisionHistory
extends RefCounted

## Records recent selection details by chunk key for the debug panel

var _selector: ChunkSelector
var _get_next_chunk_key: Callable
var _decisions: Dictionary[int, ChunkSelectionDetails] = { }
var _next_chunk_key_at_load: int = 0


func _init(selector: ChunkSelector, get_next_chunk_key: Callable) -> void:
	_selector = selector
	_get_next_chunk_key = get_next_chunk_key
	_selector.selection_history_reset.connect(_clear)


func _clear() -> void:
	_decisions.clear()
	_next_chunk_key_at_load = 0


func is_recording() -> bool:
	return _selector.selection_made.is_connected(_record)


func set_recording(enabled: bool) -> void:
	if enabled == is_recording():
		return
	if enabled:
		_selector.selection_made.connect(_record)
	else:
		_selector.selection_made.disconnect(_record)


## Restored chunks have saved identities and seeds but no recorded filter results
func record_loaded_chunks(data: ChunkSaveData) -> void:
	_next_chunk_key_at_load = data.next_chunk_key
	for chunk_key: int in data.active_chunk_keys.slice(-ChunkSelector.RECENT_CHUNK_HISTORY_SIZE):
		var decision: ChunkSelectionDetails = ChunkSelectionDetails.new()
		decision.restored_scene_uid = data.chunk_key_to_scene_uid[chunk_key]
		decision.chunk_seed = ProceduralId.chunk_seed(data.world_seed, chunk_key)
		_store_decision(chunk_key, decision)


## Orders saved history, restored chunks, then new picks by when they entered history
func get_recent_scenes() -> Dictionary[int, String]:
	var scene_uids: Array[String] = _selector.get_save_state()["recent_chunk_scene_uids"]
	scene_uids = scene_uids.slice(-ChunkSelector.RECENT_CHUNK_HISTORY_SIZE)
	var next_chunk_key: int = _get_next_chunk_key.call()
	var scenes: Dictionary[int, String] = { }
	var scenes_after_load: Dictionary[int, String] = { }
	for index: int in scene_uids.size():
		var chunk_key: int = next_chunk_key - scene_uids.size() + index
		if chunk_key < _next_chunk_key_at_load:
			scenes[chunk_key] = scene_uids[index]
		else:
			scenes_after_load[chunk_key] = scene_uids[index]
	for chunk_key: int in _decisions:
		var restored_uid: String = _decisions[chunk_key].restored_scene_uid
		if not restored_uid.is_empty():
			scenes.erase(chunk_key)
			scenes[chunk_key] = restored_uid
	scenes.merge(scenes_after_load)
	return scenes


func get_decision(chunk_key: int) -> ChunkSelectionDetails:
	return _decisions.get(chunk_key)


## Receives the evaluated counts for the actual pick before selector state advances
func _record(
	chunk_seed: int,
	score: int,
	force_skill_unlock: bool,
	catalog_count: int,
	eligible_count: int,
	scheduled_count: int,
	turn_spaced_count: int,
	unseen_count: int,
	final_count: int,
) -> void:
	var state: Dictionary = _selector.get_save_state()
	var decision: ChunkSelectionDetails = ChunkSelectionDetails.new()
	decision.chunk_seed = chunk_seed
	decision.score = score
	decision.chunks_since_turn = state["chunks_since_turn"]
	decision.last_skill_score_threshold = state["last_skill_score_threshold"]
	decision.force_skill_unlock = force_skill_unlock
	decision.catalog_count = catalog_count
	decision.eligible_count = eligible_count
	decision.scheduled_count = scheduled_count
	decision.turn_spaced_count = turn_spaced_count
	decision.unseen_count = unseen_count
	decision.final_count = final_count
	var chunk_key: int = _get_next_chunk_key.call()
	_store_decision(chunk_key, decision)


func _store_decision(chunk_key: int, decision: ChunkSelectionDetails) -> void:
	_decisions[chunk_key] = decision
	if _decisions.size() > ChunkSelector.RECENT_CHUNK_HISTORY_SIZE:
		_decisions.erase(_decisions.keys().front())
