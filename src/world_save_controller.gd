## Tracks collected collectibles / killed enemies for save/load
extends Node

var _collected_collectible_ids: Dictionary[StringName, bool] = { }
var _killed_enemy_ids: Dictionary[StringName, bool] = { }


func _ready() -> void:
	CollectiblesEvents.collectible_collected.connect(_on_collectible_collected)
	CombatEvents.enemy_killed.connect(_on_enemy_killed)
	ApplicationStateManager.main_menu_requested.connect(reset_save_data)

	SaveManager.save_requested.connect(
		func(data: SaveData) -> void:
			build_save_data(data.world),
	)
	SaveManager.load_requested.connect(_on_load_requested)
	SaveManager.reset_requested.connect(reset_save_data)

#region Save & Load & Reset
func build_save_data(data: WorldSaveData) -> void:
	data.collected_collectible_ids = _collected_collectible_ids.duplicate()
	data.killed_enemy_ids = _killed_enemy_ids.duplicate()


func _on_load_requested(data: SaveData) -> void:
	apply_save_data(data.world)


func reset_save_data() -> void:
	_collected_collectible_ids.clear()
	_respawn_collectibles()

	_killed_enemy_ids.clear()
	_respawn_enemies()


func apply_save_data(data: WorldSaveData) -> void:
	_collected_collectible_ids = data.collected_collectible_ids.duplicate()
	_killed_enemy_ids = data.killed_enemy_ids.duplicate()
	_disable_collected_collectibles.call_deferred()
	_disable_killed_enemies.call_deferred()

#endregion

#region Collectible
func _respawn_collectibles() -> void:
	for collectible: Collectible in get_tree().get_nodes_in_group(Groups.COLLECTIBLES):
		if collectible.collected:
			collectible.show()
			collectible.monitoring = true


func _disable_collected_collectibles() -> void:
	for c: Node in get_tree().get_nodes_in_group(Groups.COLLECTIBLES):
		var collectible: Collectible = c as Collectible
		if collectible == null:
			continue
		if _collected_collectible_ids.has(collectible.collectible_id):
			collectible.disable()


func is_collectible_collected(persistent_id: StringName) -> bool:
	return _collected_collectible_ids.has(persistent_id)


func _on_collectible_collected(id: StringName) -> void:
	_collected_collectible_ids[id] = true
#endregion

#region Enemy
func _respawn_enemies() -> void:
	for enemy: Node in get_tree().get_nodes_in_group(Groups.ENEMIES):
		var entity: AggressiveEntity = enemy as AggressiveEntity
		if entity == null or entity.is_procedurally_spawned:
			continue
		entity.revive()


func _disable_killed_enemies() -> void:
	for enemy: Node in get_tree().get_nodes_in_group(Groups.ENEMIES):
		var entity: AggressiveEntity = enemy as AggressiveEntity
		if entity == null:
			continue
		if _killed_enemy_ids.has(entity.enemy_id):
			entity.disable_entity()


func is_enemy_killed(persistent_id: StringName) -> bool:
	return _killed_enemy_ids.has(persistent_id)


func _on_enemy_killed(id: StringName) -> void:
	_killed_enemy_ids[id] = true
#endregion
