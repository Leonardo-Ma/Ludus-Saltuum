# https://refactoring.guru/design-patterns/observer
extends Node

#region Player
@warning_ignore("unused_signal")
signal player_spawning(player: Node3D)
@warning_ignore("unused_signal")
signal player_finished_spawning(player: Node3D)

signal player_respawning(duration: float)
signal player_finished_respawning

signal controlled_entity_changed(entity: Node3D)
#endregion

var controlled_entity: Node3D = null


func _ready() -> void:
	player_respawning.connect(_on_player_respawning)
	player_finished_respawning.connect(SaveManager.release_save_block.bind(&"player_respawning"))


func set_controlled_entity(entity: Node3D) -> void:
	controlled_entity = entity
	controlled_entity_changed.emit(entity)


# BUG If something passes is_death = true and doesn't kill the player, it bypasses health and restores player health to max
## Request respawn for currently controlled entity
## Entity must implement respawn
func request_respawn(delay: float, target_transform: Transform3D, is_death: bool = false) -> void:
	assert(controlled_entity != null, "No controlled entity to respawn")
	assert(
		controlled_entity.has_method("respawn"),
		"Controlled entity " + controlled_entity.name + " must implement respawn(delay: float, target_transform: Transform3D, is_death: bool)",
	)
	controlled_entity.respawn(delay, target_transform, is_death)


func _on_player_respawning(_duration: float) -> void:
	SaveManager.request_save_block(&"player_respawning")
