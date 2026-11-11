class_name PlayerRespawnController
extends Node

## Player respawn sequence, return to checkpoint and death follow-up

const DEATH_RESPAWN_DELAY: float = 2.0
const CHECKPOINT_RETURN_DELAY: float = 1.0
const DEATH_SCORE_PENALTY: int = 10

var _player: PlayerEntity
var _initialized: bool = false


func _ready() -> void:
	_initialize.call_deferred()


func _initialize() -> void:
	_player = owner as PlayerEntity
	assert(_player != null, "PlayerEntity owner missing for " + name)

	_initialized = true
	owner.input_controller.return_to_checkpoint_requested.connect(_on_return_to_checkpoint_requested)


func respawn(delay: float, target_transform: Transform3D, is_death: bool = false) -> void:
	ControlledEntityEvents.player_respawning.emit(delay)

	owner.player_movement_controller.disable_movement(delay)
	owner.velocity = Vector3.ZERO

	# Wait for the screen to fade in
	await get_tree().create_timer(delay).timeout

	owner.global_position = target_transform.origin
	owner.global_rotation.y = atan2(target_transform.basis.z.x, target_transform.basis.z.z)

	owner.player_movement_controller.enable_movement()
	owner.player_movement_controller.disable_movement(delay / 2.0)

	owner.status_manager.clear_temporary_statuses()

	if is_death:
		owner.health.reset()
		owner.scale = Vector3.ONE

	owner.input_controller.set_process_input(true)
	owner.input_controller.set_process_unhandled_input(true)

	owner.hitbox.set_deferred("monitoring", true)
	owner.hitbox.set_deferred("monitorable", true)

	owner.hurtbox.set_deferred("monitoring", true)
	owner.hurtbox.set_deferred("monitorable", true)

	ControlledEntityEvents.player_finished_respawning.emit()
	# TODO This is needed because parent class unifies disable entity upon death for players and NPCs
	owner.set_state(PlayerEntity.PlayerState.ACTIVE)


func on_death_complete() -> void:
	owner.economy_controller.remove_score(DEATH_SCORE_PENALTY)
	ControlledEntityEvents.request_respawn(DEATH_RESPAWN_DELAY, CheckpointManager.get_respawn_transform(), true)


func finish_load() -> void:
	owner.velocity = Vector3.ZERO
	owner.player_movement_controller.enable_movement()


func _on_return_to_checkpoint_requested() -> void:
	if owner.health.current_health <= 0:
		return
	ControlledEntityEvents.request_respawn(CHECKPOINT_RETURN_DELAY, CheckpointManager.get_respawn_transform())
