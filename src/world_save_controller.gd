# TODO Consider a different approach?
## Tracks consumed collectibles / killed enemies for save/load
extends Node

const _COLLECTIBLE_MATCH_SQ: float = 0.25
const _ENEMY_MATCH_SQ: float = 0.25

var _consumed_collectible_positions: Array[Vector3] = []
var _killed_enemy_positions: Array[Vector3] = []


func _ready() -> void:
	GameEvents.collectible_consumed.connect(_on_collectible_consumed)
	GameEvents.enemy_killed.connect(_on_enemy_killed)
	ApplicationStateManager.main_menu_requested.connect(reset_data)


## Builds world data for saving
## @param data WorldSaveData resource to populate
func build_save(data: WorldSaveData) -> void:
	data.collected_collectible_positions = _consumed_collectible_positions.duplicate()
	data.killed_enemy_positions = _killed_enemy_positions.duplicate()


## Applies world data when loading a save
## @param data WorldSaveData resource to apply
func apply_save(data: WorldSaveData) -> void:
	_consumed_collectible_positions = data.collected_collectible_positions.duplicate()
	_killed_enemy_positions = data.killed_enemy_positions.duplicate()
	_disable_killed_enemies.call_deferred()
	_disable_consumed_collectibles.call_deferred()


func reset_data() -> void:
	_consumed_collectible_positions.clear()
	_killed_enemy_positions.clear()


func _on_collectible_consumed(pos: Vector3) -> void:
	_consumed_collectible_positions.append(pos)


func _on_enemy_killed(pos: Vector3) -> void:
	_killed_enemy_positions.append(pos)


# TODO BUG Improve this garbage
func _disable_consumed_collectibles() -> void:
	for pos: Vector3 in _consumed_collectible_positions:
		for c: Node in get_tree().get_nodes_in_group(Groups.COLLECTIBLES):
			var collectible: Collectible = c as Collectible
			if collectible == null:
				continue
			if pos.distance_squared_to(collectible.spawn_position) < _COLLECTIBLE_MATCH_SQ:
				c.queue_free()
				break


# TODO BUG Improve this garbage
func _disable_killed_enemies() -> void:
	for pos: Vector3 in _killed_enemy_positions:
		for enemy: Node in get_tree().get_nodes_in_group(Groups.ENEMIES):
			var entity: AggressiveEntity = enemy as AggressiveEntity
			if entity == null:
				continue
			if pos.distance_squared_to(entity.spawn_position) < _ENEMY_MATCH_SQ:
				enemy.queue_free()
				break
