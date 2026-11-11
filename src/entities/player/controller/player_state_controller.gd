class_name PlayerStateController
extends Node

## Player activity state (menus, gameplay, vehicle) and every system toggled by it

var state: PlayerEntity.PlayerState = PlayerEntity.PlayerState.INACTIVE

var _player: PlayerEntity
var _initialized: bool = false


func _ready() -> void:
	ApplicationStateManager.state_changed.connect(_on_application_state_changed)
	_initialize.call_deferred()


func _initialize() -> void:
	_player = owner as PlayerEntity
	assert(_player != null, "PlayerEntity owner missing for " + name)

	_initialized = true
	_on_application_state_changed(ApplicationStateManager.get_current_state(), ApplicationStateManager.get_previous_state())


func set_state(new_state: PlayerEntity.PlayerState) -> void:
	assert(_initialized, "PlayerStateController not initialized for " + name)

	state = new_state
	var is_active: bool = new_state == PlayerEntity.PlayerState.ACTIVE
	if is_active:
		ControlledEntityEvents.set_controlled_entity(_player)
		_player.add_to_group(Groups.CONTROLLED)
	else:
		_player.remove_from_group(Groups.CONTROLLED)
	_player.skills_controller.set_physics_process(is_active)
	_player.set_collision_layer_value(1, is_active)
	_player.collision_shape.set_deferred("disabled", not is_active)
	_player.hurtbox.set_deferred("monitoring", is_active)
	_player.hurtbox.set_deferred("monitorable", is_active)
	_player.hitbox.set_deferred("monitoring", is_active)
	_player.hitbox.set_deferred("monitorable", is_active)
	_player.camera_controller.set_active(is_active)
	_player.set_physics_process(is_active)
	_player.visible = is_active


func _on_application_state_changed(new_state: ApplicationStateManager.GameState, _previous_state: ApplicationStateManager.GameState) -> void:
	if not _initialized:
		return

	# TODO Double check this
	if state == PlayerEntity.PlayerState.IN_VEHICLE:
		return
	set_state(PlayerEntity.PlayerState.ACTIVE if new_state == ApplicationStateManager.GameState.PLAYING else PlayerEntity.PlayerState.INACTIVE)
