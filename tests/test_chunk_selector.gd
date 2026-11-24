extends ProjectTest

## Verifies ChunkSelector required-skill filtering, turn cooldown, and forced skill unlock

const DASH: SkillDefinition = preload("uid://dq338q84ai7to") # dash.tres


func _make_chunk(
	path: String,
	required: Array[SkillDefinition] = [],
	unlocks: SkillDefinition = null,
	is_turn: bool = false,
	min_score: int = 0,
) -> ChunkData:
	var data: ChunkData = ChunkData.new()
	data.scene_path = path
	data.scene_uid = path
	data.required_skill = required
	data.unlocks_skill = unlocks
	data.is_turn = is_turn
	data.min_score = min_score
	return data


func run_tests() -> void:
	_test_filters_by_required_skills()
	_test_turn_cooldown()
	_test_forced_skill_unlock()
	_test_filters_by_min_score()
	_test_fallback_preserves_requirements()
	_test_relaxes_unlock_scheduling_last()
	_test_empty_pool_keeps_state()
	_test_deterministic_picks()
	print("ChunkSelector test completed.")


func _test_filters_by_required_skills() -> void:
	var basic: ChunkData = _make_chunk("res://basic.tscn")
	var dash_only: ChunkData = _make_chunk("res://dash.tscn", [DASH])
	var selector: ChunkSelector = ChunkSelector.new([basic, dash_only])

	for i: int in 10:
		var chosen: ChunkData = selector.select_deterministic_chunk_data(Transform3D(), 0, [], 0)
		assert(chosen.scene_path == "res://basic.tscn", "ChunkSelector: selected chunk requiring unowned skill 'dash'")


func _test_turn_cooldown() -> void:
	var turn: ChunkData = _make_chunk("res://turn.tscn", [], null, true)
	var straight: ChunkData = _make_chunk("res://straight.tscn", [], null, false)
	var selector: ChunkSelector = ChunkSelector.new([turn, straight])
	selector._chunks_since_turn = 0 # simulate a turn was just selected

	var chosen: ChunkData = selector.select_deterministic_chunk_data(Transform3D(), 0, [], 0)
	assert(chosen.scene_path == "res://straight.tscn", "ChunkSelector: turn chunk selected immediately after a previous turn")
	assert(selector._chunks_since_turn == 1, "ChunkSelector: _chunks_since_turn not incremented after straight chunk selection")


func _test_forced_skill_unlock() -> void:
	var basic: ChunkData = _make_chunk("res://basic.tscn")
	var unlock_dash: ChunkData = _make_chunk("res://unlock_dash.tscn", [], DASH)
	var selector: ChunkSelector = ChunkSelector.new([basic, unlock_dash])
	selector._chunks_since_skill_unlock = ChunkSelector.MIN_CHUNKS_BETWEEN_SKILLS

	var chosen: ChunkData = selector.select_deterministic_chunk_data(Transform3D(), 0, [], ChunkSelector.SKILL_UNLOCK_SCORE_STEP)
	assert(chosen.scene_path == "res://unlock_dash.tscn", "ChunkSelector: expected forced skill unlock chunk once score threshold reached")
	assert(selector._chunks_since_skill_unlock == 0, "ChunkSelector: _chunks_since_skill_unlock not reset after skill unlock chunk chosen")


func _test_filters_by_min_score() -> void:
	var basic: ChunkData = _make_chunk("res://basic.tscn")
	var gated: ChunkData = _make_chunk("res://gated.tscn", [], null, false, 100)
	var selector: ChunkSelector = ChunkSelector.new([basic, gated])

	for i: int in 10:
		var chosen: ChunkData = selector.select_deterministic_chunk_data(Transform3D(), i, [], 99)
		assert(chosen.scene_path == "res://basic.tscn", "ChunkSelector: selected chunk below min_score")

	var first: ChunkData = selector.select_deterministic_chunk_data(Transform3D(), 0, [], 100)
	var second: ChunkData = selector.select_deterministic_chunk_data(Transform3D(), 1, [], 100)
	assert(first == gated or second == gated, "ChunkSelector: chunk at min_score never selectable")


func _test_fallback_preserves_requirements() -> void:
	var features: Array[ChunkFeature.Feature] = [ChunkFeature.Feature.CAR, ChunkFeature.Feature.PORTAL]
	var turn: ChunkData = _make_chunk("res://turn.tscn", [], null, true)
	turn.features = features.duplicate()
	var wrong_feature: ChunkData = _make_chunk("res://car_only.tscn")
	wrong_feature.features = [ChunkFeature.Feature.CAR]
	var gated: ChunkData = _make_chunk("res://gated.tscn", [], null, false, 51)
	gated.features = features.duplicate()
	var skill_only: ChunkData = _make_chunk("res://skill_only.tscn", [DASH])
	skill_only.features = features.duplicate()
	var locked_unlock: ChunkData = _make_chunk("res://locked_unlock.tscn", [], DASH, false, 51)
	locked_unlock.features = features.duplicate()
	var selector: ChunkSelector = ChunkSelector.new([turn, wrong_feature, gated, skill_only, locked_unlock])

	for i: int in 3:
		var chosen: ChunkData = selector.select_deterministic_chunk_data(Transform3D(), i, [], 50, features)
		assert(chosen == turn, "Fallback selected a chunk missing mandatory requirements in " + name)
	assert(selector.get_save_state()["last_skill_score_threshold"] == 0, "Unavailable unlock consumed a score threshold in " + name)


func _test_relaxes_unlock_scheduling_last() -> void:
	var straight: ChunkData = _make_chunk("res://straight.tscn")
	var turn: ChunkData = _make_chunk("res://turn.tscn", [], null, true)
	var unlock: ChunkData = _make_chunk("res://unlock.tscn", [], DASH, true)
	unlock.features = [ChunkFeature.Feature.CAR]
	var selector: ChunkSelector = ChunkSelector.new([straight, turn, unlock])
	selector.load_save_state({ "recent_chunk_scene_uids": [straight.scene_uid], "chunks_since_turn": 0 })
	var chosen: ChunkData = selector.select_deterministic_chunk_data(Transform3D(), 0, [], 0)
	assert(chosen == straight, "Recency took priority over turn spacing in " + name)
	chosen = selector.select_deterministic_chunk_data(Transform3D(), 0, [], ChunkSelector.SKILL_UNLOCK_SCORE_STEP)
	assert(chosen == unlock, "Turn spacing took priority over a scheduled unlock in " + name)

	selector.reset()
	chosen = selector.select_deterministic_chunk_data(Transform3D(), 0, [], 0, unlock.features)
	assert(chosen == unlock, "Unlock scheduling blocked the only eligible route in " + name)
	assert(selector.get_save_state()["last_skill_score_threshold"] == 0, "Early unlock consumed an unreached score threshold in " + name)

	chosen = selector.select_deterministic_chunk_data(Transform3D(), 0, [DASH], 0, unlock.features)
	assert(chosen == unlock, "Previously unlocked route could not satisfy requested features in " + name)
	assert(selector.get_save_state()["chunks_since_skill_unlock"] == 1, "Owned skill counted as a new unlock in " + name)


func _test_empty_pool_keeps_state() -> void:
	var gated: ChunkData = _make_chunk("res://gated.tscn", [DASH], null, false, 50)
	var selector: ChunkSelector = ChunkSelector.new([gated])
	var initial_state: Dictionary = selector.get_save_state()
	assert(selector.select_deterministic_chunk_data(Transform3D(), 0, [], 0) == null, "Empty eligible pool produced a route in " + name)
	assert(
		selector.select_deterministic_chunk_data(Transform3D(), 0, [DASH], 50, [ChunkFeature.Feature.CAR]) == null,
		"Missing requested feature produced a route in " + name,
	)
	assert(selector.get_save_state() == initial_state, "An unsuccessful selection changed state in " + name)
	var empty_selector: ChunkSelector = ChunkSelector.new([])
	assert(empty_selector.select_deterministic_chunk_data(Transform3D(), 0, [], 0) == null, "Empty catalog produced a route in " + name)


func _test_deterministic_picks() -> void:
	var chunks: Array[ChunkData] = [
		_make_chunk("res://straight_a.tscn"),
		_make_chunk("res://straight_b.tscn"),
		_make_chunk("res://turn.tscn", [], null, true),
	]
	var first: ChunkSelector = ChunkSelector.new(chunks)
	var second: ChunkSelector = ChunkSelector.new(chunks)
	for seed_value: int in 20:
		var first_pick: ChunkData = first.select_deterministic_chunk_data(Transform3D(), seed_value, [], 0)
		var second_pick: ChunkData = second.select_deterministic_chunk_data(Transform3D(), seed_value, [], 0)
		assert(first_pick == second_pick and first_pick != null, "Identical seeds and state selected different routes in " + name)
	assert(first.get_save_state() == second.get_save_state(), "Identical picks produced different selector state in " + name)
