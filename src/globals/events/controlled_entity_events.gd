# TODO Maybe change this to be a controlled to be attached to possible controlled entities?
extends Node

#region Player
@warning_ignore("unused_signal")
signal player_spawning(player: Node3D)
@warning_ignore("unused_signal")
signal player_finished_spawning(player: Node3D)

signal player_respawning(duration: float)
signal player_respawn_arrived
signal player_finished_respawning

signal controlled_entity_changed(entity: Node3D)
#endregion

var controlled_entity: Node3D = null
var _respawn_owner: Node3D

const RESPAWN_FADE_DURATION: float = 0.5


func _ready() -> void:
	player_respawning.connect(_on_player_respawning)
	player_finished_respawning.connect(SaveManager.release_save_block.bind(&"player_respawning"))


func set_controlled_entity(entity: Node3D) -> void:
	controlled_entity = entity
	controlled_entity_changed.emit(entity)


# Guard against bypassing health by passing is_death for a living player
## Request respawn for currently controlled entity
## Entity implements its own respawn sequence
func request_respawn(delay: float, target_transform: Transform3D, is_death: bool = false) -> void:
	if controlled_entity is PlayerEntity:
		var player: PlayerEntity = controlled_entity
		player.respawn(delay, target_transform, is_death)
	elif controlled_entity is PlayerCar:
		var car: PlayerCar = controlled_entity
		car.recover_at(delay, target_transform)
	else:
		assert(false, "Player or vehicle missing in " + name)


func begin_respawn(entity: Node3D, duration: float) -> void:
	if entity == controlled_entity:
		_respawn_owner = entity
		player_respawning.emit(duration)


func arrive_at_respawn(entity: Node3D) -> void:
	if _respawn_owner == entity:
		player_respawn_arrived.emit()


func finish_respawn(entity: Node3D) -> void:
	if _respawn_owner == entity:
		_respawn_owner = null
		player_finished_respawning.emit()


func _on_player_respawning(_duration: float) -> void:
	SaveManager.request_save_block(&"player_respawning")
