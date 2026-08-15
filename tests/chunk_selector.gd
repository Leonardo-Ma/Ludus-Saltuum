## Verifies ChunkSelector required-skill filtering, turn cooldown, and forced skill unlock
extends Node


func _make_chunk(path: String, required: Array[StringName] = [], unlocks: StringName = &"", is_turn: bool = false) -> ChunkData:
	var data: ChunkData = ChunkData.new()
	data.scene_path = path
	data.required_skill_ids = required
	data.unlocks_skill_id = unlocks
	data.is_turn = is_turn
	return data


func _ready() -> void:
	_test_filters_by_required_skills()
	_test_turn_cooldown()
	_test_forced_skill_unlock()
	print("ChunkSelector test completed.")
	self.queue_free()


func _test_filters_by_required_skills() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 1

	var basic: ChunkData = _make_chunk("res://basic.tscn")
	var dash_only: ChunkData = _make_chunk("res://dash.tscn", [&"dash"])
	var selector: ChunkSelector = ChunkSelector.new(rng, [basic, dash_only])

	for i: int in 10:
		var chosen: ChunkData = selector.select_chunk_data(Transform3D(), [], 0)
		assert(chosen.scene_path == "res://basic.tscn", "ChunkSelector: selected chunk requiring unowned skill 'dash'")


func _test_turn_cooldown() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 2

	var turn: ChunkData = _make_chunk("res://turn.tscn", [], &"", true)
	var straight: ChunkData = _make_chunk("res://straight.tscn", [], &"", false)
	var selector: ChunkSelector = ChunkSelector.new(rng, [turn, straight])
	selector._chunks_since_turn = 0  # simulate a turn was just selected

	var chosen: ChunkData = selector.select_chunk_data(Transform3D(), [], 0)
	assert(chosen.scene_path == "res://straight.tscn", "ChunkSelector: turn chunk selected immediately after a previous turn")
	assert(selector._chunks_since_turn == 1, "ChunkSelector: _chunks_since_turn not incremented after straight chunk selection")


func _test_forced_skill_unlock() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 3

	var basic: ChunkData = _make_chunk("res://basic.tscn")
	var unlock_dash: ChunkData = _make_chunk("res://unlock_dash.tscn", [], &"dash")
	var selector: ChunkSelector = ChunkSelector.new(rng, [basic, unlock_dash])
	selector._chunks_since_skill_unlock = ChunkSelector.MIN_CHUNKS_BETWEEN_SKILLS

	var chosen: ChunkData = selector.select_chunk_data(Transform3D(), [], ChunkSelector.SKILL_UNLOCK_SCORE_STEP)
	assert(chosen.scene_path == "res://unlock_dash.tscn", "ChunkSelector: expected forced skill unlock chunk once score threshold reached")
	assert(selector._chunks_since_skill_unlock == 0, "ChunkSelector: _chunks_since_skill_unlock not reset after skill unlock chunk chosen")
