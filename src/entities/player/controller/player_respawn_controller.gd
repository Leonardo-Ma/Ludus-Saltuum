class_name PlayerRespawnController
extends Node

## Player respawn sequence, return to checkpoint and death follow-up

const DEATH_RESPAWN_DELAY: float = 2.0
const CHECKPOINT_RETURN_DELAY: float = 1.0
const DEATH_SCORE_PENALTY: int = 10

var _player: PlayerEntity
var _respawn_tween: Tween

@onready var _input: InputController = %InputController
@onready var _movement: PlayerMovementComponent = %PlayerMovementComponent
@onready var _economy: EconomyController = %EconomyController


func initialize() -> void:
	_player = owner
	assert(_player, "PlayerEntity owner missing for " + name)
	assert(_input and _movement and _economy, "Respawn dependencies missing in " + name)
	ApplicationStateManager.main_menu_requested.connect(_cancel_respawn)
	_input.return_to_checkpoint_requested.connect(_on_return_to_checkpoint_requested)


func _exit_tree() -> void:
	_cancel_respawn()


func is_respawning() -> bool:
	return _respawn_tween != null


func respawn(delay: float, target_transform: Transform3D, is_death: bool = false) -> void:
	assert(delay >= 0.0, "Invalid respawn delay in " + name)
	if _player.health.current_health <= 0 and not is_death:
		return

	if is_respawning():
		_respawn_tween.kill()
	_respawn_tween = create_tween()
	_respawn_tween.set_pause_mode(Tween.TWEEN_PAUSE_STOP)
	# Wait for the screen to fade in
	_respawn_tween.tween_interval(delay)
	_respawn_tween.tween_callback(_arrive.bind(target_transform, is_death))
	_respawn_tween.tween_interval(maxf(delay / 2.0, ControlledEntityEvents.RESPAWN_FADE_DURATION))
	_respawn_tween.tween_callback(_finish_respawn)

	_player.velocity = Vector3.ZERO
	_player.refresh_state()
	ControlledEntityEvents.begin_respawn(_player, delay)


func _arrive(target_transform: Transform3D, is_death: bool) -> void:
	_player.velocity = Vector3.ZERO
	_movement.consume_external_force()
	_player.global_position = target_transform.origin
	_player.global_rotation.y = atan2(target_transform.basis.z.x, target_transform.basis.z.z)
	_player.status_manager.clear_temporary_statuses()

	if is_death and _player.health.current_health <= 0:
		_player.revive()
	# TODO This is needed because parent class unifies disable entity upon death for players and NPCs
	_player.refresh_state()
	ControlledEntityEvents.arrive_at_respawn(_player)


func _finish_respawn() -> void:
	_respawn_tween = null
	_movement.consume_external_force()
	_movement.enable_movement()
	_player.refresh_state()
	if not is_respawning():
		ControlledEntityEvents.finish_respawn(_player)


func _cancel_respawn() -> void:
	if is_respawning():
		_respawn_tween.kill()
		_respawn_tween = null
		ControlledEntityEvents.finish_respawn(_player)


func on_death_complete() -> void:
	if ApplicationStateManager.has_active_run():
		_economy.remove_score(DEATH_SCORE_PENALTY)
		respawn(DEATH_RESPAWN_DELAY, CheckpointManager.get_respawn_transform(), true)


func finish_load() -> void:
	_cancel_respawn()
	_player.velocity = Vector3.ZERO
	_movement.consume_external_force()
	_movement.enable_movement()
	_player.refresh_state()


func _on_return_to_checkpoint_requested() -> void:
	respawn(CHECKPOINT_RETURN_DELAY, CheckpointManager.get_respawn_transform())
