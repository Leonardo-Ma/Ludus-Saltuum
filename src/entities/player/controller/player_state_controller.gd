class_name PlayerStateController
extends Node

## Player activity state (menus, gameplay, vehicle) and every system toggled by it

var state: PlayerEntity.PlayerState = PlayerEntity.PlayerState.INACTIVE

var _player: PlayerEntity
var _initialized: bool = false


func _ready() -> void:
	_player = owner
	assert(_player != null, "PlayerEntity owner missing for " + name)
	_player.ready.connect(_initialize, CONNECT_ONE_SHOT)
	ApplicationStateManager.state_changed.connect(_on_application_state_changed)


func _initialize() -> void:
	_initialized = true
	_on_application_state_changed(ApplicationStateManager.get_current_state(), ApplicationStateManager.get_previous_state())


func set_state(new_state: PlayerEntity.PlayerState) -> void:
	assert(_initialized, "PlayerStateController not initialized for " + name)

	_player.state = new_state
	var is_active: bool = new_state == PlayerEntity.PlayerState.ACTIVE
	var simulate_physics: bool = is_active and _player.health.current_health > 0
	var can_control: bool = simulate_physics and not _player.is_respawning
	if is_active:
		if not _player.is_in_group(Groups.CONTROLLED):
			_player.add_to_group(Groups.CONTROLLED)
		if ControlledEntityEvents.controlled_entity != _player:
			ControlledEntityEvents.set_controlled_entity(_player)
	else:
		_player.remove_from_group(Groups.CONTROLLED)
	_player.input_controller.set_gameplay_input_enabled(can_control)
	_player.skills_controller.set_physics_process(can_control)
	_player.set_collision_layer_value(1, can_control)
	_player.collision_shape.set_deferred("disabled", not simulate_physics)
	_player.hurtbox.set_deferred("monitoring", can_control)
	_player.hurtbox.set_deferred("monitorable", can_control)
	_player.hitbox.set_deferred("monitoring", can_control)
	_player.hitbox.set_deferred("monitorable", can_control)
	_player.camera_controller.set_active(is_active)
	_player.camera_controller.set_process_input(can_control)
	_player.camera_controller.set_process(can_control)
	_player.set_physics_process(simulate_physics)
	_player.visible = is_active


func refresh_state() -> void:
	if _player.vehicle_rider.is_in_vehicle:
		set_state(PlayerEntity.PlayerState.IN_VEHICLE)
	elif ApplicationStateManager.is_in_state(ApplicationStateManager.GameState.PLAYING):
		set_state(PlayerEntity.PlayerState.ACTIVE)
	else:
		set_state(PlayerEntity.PlayerState.INACTIVE)


func _on_application_state_changed(_new_state: ApplicationStateManager.GameState, _previous_state: ApplicationStateManager.GameState) -> void:
	if not _initialized:
		return

	# TODO Double check this
	refresh_state()
