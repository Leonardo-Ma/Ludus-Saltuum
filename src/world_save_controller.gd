# TODO Consider a different approach?
## Tracks world state during gameplay (consumed collectibles, killed enemies)
## Used by SaveManager during save/load operations
class_name WorldSaveController
extends RefCounted

const _COLLECTIBLE_MATCH_SQ: float = 0.25
const _ENEMY_MATCH_SQ: float = 0.25

static var _consumed_collectible_positions: Array[Vector3] = []
static var _killed_enemy_positions: Array[Vector3] = []
static var _is_initialized: bool = false


static func _get_tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


static func _ensure_initialized() -> void:
	if _is_initialized:
		return
	_is_initialized = true
	GameEvents.collectible_consumed.connect(_on_collectible_consumed)
	GameEvents.enemy_killed.connect(_on_enemy_killed)
	ApplicationStateManager.main_menu_requested.connect(_cleanup)


static func _cleanup() -> void:
	if not _is_initialized:
		return
	_is_initialized = false
	GameEvents.collectible_consumed.disconnect(_on_collectible_consumed)
	GameEvents.enemy_killed.disconnect(_on_enemy_killed)
	ApplicationStateManager.main_menu_requested.disconnect(_cleanup)


## Builds world data for saving
## @param data WorldSaveData resource to populate
static func build_save(data: WorldSaveData) -> void:
	_ensure_initialized()
	data.collected_collectible_positions = _consumed_collectible_positions.duplicate()
	data.killed_enemy_positions = _killed_enemy_positions.duplicate()


## Applies world data when loading a save
## @param data WorldSaveData resource to apply
static func apply_save(data: WorldSaveData) -> void:
	_ensure_initialized()
	_consumed_collectible_positions = data.collected_collectible_positions.duplicate()
	_killed_enemy_positions = data.killed_enemy_positions.duplicate()

	_disable_killed_enemies.call_deferred()
	_disable_consumed_collectibles.call_deferred()


## Resets world state for new game
static func reset_data() -> void:
	_ensure_initialized()
	_consumed_collectible_positions.clear()
	_killed_enemy_positions.clear()


static func _on_collectible_consumed(pos: Vector3) -> void:
	_consumed_collectible_positions.append(pos)


static func _on_enemy_killed(pos: Vector3) -> void:
	_killed_enemy_positions.append(pos)


# TODO BUG Improve this garbage
static func _disable_consumed_collectibles() -> void:
	var tree: SceneTree = _get_tree()
	for pos: Vector3 in _consumed_collectible_positions:
		for c: Node in tree.get_nodes_in_group(Groups.COLLECTIBLES):
			var collectible: Collectible = c as Collectible
			if collectible == null:
				continue
			if pos.distance_squared_to(collectible.spawn_position) < _COLLECTIBLE_MATCH_SQ:
				c.queue_free()
				break


# TODO BUG Improve this garbage
static func _disable_killed_enemies() -> void:
	var tree: SceneTree = _get_tree()
	for pos: Vector3 in _killed_enemy_positions:
		for enemy: Node in tree.get_nodes_in_group(Groups.ENEMIES):
			var entity: AggressiveEntity = enemy as AggressiveEntity
			if entity == null:
				continue
			if pos.distance_squared_to(entity.spawn_position) < _ENEMY_MATCH_SQ:
				enemy.queue_free()
				break
