class_name PlayerStateController
extends Node

## Player activity state (menus, gameplay, vehicle) and every system toggled by it

var state: PlayerEntity.PlayerState = PlayerEntity.PlayerState.INACTIVE

var _player: PlayerEntity
var _initialized: bool = false

@onready var _input: InputController = %InputController
@onready var _skills: SkillsController = %SkillsController
@onready var _camera: CameraController = %CamRoot
@onready var _vehicle_rider: VehicleRider = %VehicleRider


func initialize() -> void:
	_player = owner
	assert(_player, "PlayerEntity owner missing for " + name)
	assert(_input and _skills and _camera and _vehicle_rider, "State dependencies missing in " + name)
	_initialized = true
	ApplicationStateManager.state_changed.connect(_on_application_state_changed)
	refresh_state()


func set_state(new_state: PlayerEntity.PlayerState) -> void:
	assert(_initialized, "PlayerStateController not initialized for " + name)

	state = new_state
	var is_active: bool = new_state == PlayerEntity.PlayerState.ACTIVE
	var simulate_physics: bool = is_active and _player.health.current_health > 0
	var can_control: bool = simulate_physics and not _player.is_respawning
	if not can_control:
		_player.interrupt_melee_attack()
	if is_active:
		if not _player.is_in_group(Groups.CONTROLLED):
			_player.add_to_group(Groups.CONTROLLED)
	else:
		_player.remove_from_group(Groups.CONTROLLED)
	_input.set_gameplay_input_enabled(can_control)
	_skills.set_physics_process(can_control)
	_player.set_collision_layer_value(1, can_control)
	_player.collision_shape.set_deferred("disabled", not simulate_physics)
	_player.hurtbox.set_deferred("monitoring", can_control)
	_player.hurtbox.set_deferred("monitorable", can_control)
	_player.hitbox.set_deferred("monitoring", can_control)
	_player.hitbox.set_deferred("monitorable", can_control)
	_camera.set_active(is_active)
	_camera.set_process_input(can_control)
	_camera.set_process(can_control)
	_player.set_physics_process(simulate_physics)
	_player.visible = is_active
	if is_active and ControlledEntityEvents.controlled_entity != _player:
		ControlledEntityEvents.set_controlled_entity(_player)


func refresh_state() -> void:
	if _vehicle_rider.is_in_vehicle:
		set_state(PlayerEntity.PlayerState.IN_VEHICLE)
	elif ApplicationStateManager.is_in_state(ApplicationStateManager.GameState.PLAYING):
		set_state(PlayerEntity.PlayerState.ACTIVE)
	else:
		set_state(PlayerEntity.PlayerState.INACTIVE)


func _on_application_state_changed(_new_state: ApplicationStateManager.GameState, _previous_state: ApplicationStateManager.GameState) -> void:
	# TODO Double check this
	refresh_state()
