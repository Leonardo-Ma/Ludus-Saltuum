extends SaveController

## Tracks collected collectibles / killed enemies for save/load

const ENTITY_ID_VERSION: int = 1

var _collected_collectible_ids: Dictionary[StringName, bool] = { }
var _killed_enemy_ids: Dictionary[StringName, bool] = { }


func _child_ready() -> void:
	CollectiblesEvents.collectible_collected.connect(_on_collectible_collected)
	CombatEvents.enemy_killed.connect(_on_enemy_killed)
	ApplicationStateManager.main_menu_requested.connect(initialize_new_save_data)


func _on_save_requested(data: SaveData) -> void:
	build_save_data(data.world)


#region Save & Load & Reset
func build_save_data(data: WorldSaveData) -> void:
	data.entity_id_version = ENTITY_ID_VERSION
	data.collected_collectible_ids = _collected_collectible_ids.duplicate()
	data.killed_enemy_ids = _killed_enemy_ids.duplicate()


func initialize_new_save_data() -> void:
	_collected_collectible_ids.clear()
	_killed_enemy_ids.clear()
	apply_saved_entity_states()


func apply_save_data(data: WorldSaveData) -> void:
	if data.entity_id_version != ENTITY_ID_VERSION:
		_collected_collectible_ids.clear()
		_killed_enemy_ids.clear()
		return
	_collected_collectible_ids = data.collected_collectible_ids.duplicate()
	_killed_enemy_ids = data.killed_enemy_ids.duplicate()


func apply_saved_entity_states(chunk: LevelChunk = null) -> void:
	var entities: Array[Node] = chunk.find_children("*", "", true, false) if chunk != null else _get_world_entities()
	for entity: Node in entities:
		if entity.is_queued_for_deletion():
			continue
		if entity is Collectible:
			var collectible: Collectible = entity
			collectible.set_collected_state(is_collectible_collected(collectible.collectible_id))
		elif entity is NPCEntity:
			var enemy: NPCEntity = entity
			enemy.apply_saved_killed_state(is_enemy_killed(enemy.enemy_id))

#endregion


## Checks authored and staged entities together before adding chunks to the scene
func has_valid_entity_ids(staged_chunks: Array[LevelChunk] = [], replaced_container: Node3D = null) -> bool:
	var entities: Array[Node] = []
	for entity: Node in _get_world_entities():
		if replaced_container != null and replaced_container.is_ancestor_of(entity):
			continue
		entities.append(entity)
	for chunk: LevelChunk in staged_chunks:
		entities.append_array(chunk.find_children("*", "", true, false))

	var ids: Dictionary[StringName, bool] = { }
	for entity: Node in entities:
		if entity.is_queued_for_deletion():
			continue
		var id: StringName
		if entity is Collectible:
			var collectible: Collectible = entity
			id = collectible.collectible_id
		elif entity is NPCEntity:
			var enemy: NPCEntity = entity
			id = enemy.enemy_id
		else:
			continue
		if id == &"" and entity.is_inside_tree() and entity.owner == null:
			continue
		if id == &"" or ids.has(id):
			return false
		ids[id] = true
	return true


func _get_world_entities() -> Array[Node]:
	var entities: Array[Node] = get_tree().get_nodes_in_group(Groups.COLLECTIBLES)
	entities.append_array(get_tree().get_nodes_in_group(Groups.ENEMIES))
	return entities


#region Collectible
func is_collectible_collected(persistent_id: StringName) -> bool:
	return _collected_collectible_ids.has(persistent_id)


func _on_collectible_collected(id: StringName) -> void:
	assert(id != &"", "Collectible ID missing in " + name)
	_collected_collectible_ids[id] = true
#endregion


#region Enemy
func is_enemy_killed(persistent_id: StringName) -> bool:
	return _killed_enemy_ids.has(persistent_id)


func _on_enemy_killed(id: StringName) -> void:
	if id != &"":
		_killed_enemy_ids[id] = true
#endregion
