class_name PlayerEntity
extends AggressiveEntity

enum PlayerState {
	INACTIVE = 0, ## Not playing (menus)
	ACTIVE = 1,
	IN_VEHICLE = 2,
}

@export_category("Skills")
@export var startup_skills: Array[SkillDefinition] = []

var state: PlayerState = PlayerState.INACTIVE

@onready var camera_controller: CameraController = %CamRoot
@onready var player_movement_controller: PlayerMovementController = %PlayerMovementController
@onready var input_controller: InputController = %InputController

@onready var player_save_controller: PlayerSaveController = %PlayerSaveController
@onready var skills_controller: SkillsController = %SkillsController
@onready var vehicle_rider: VehicleRider = %VehicleRider
@onready var portal_controller: PortalController = %PortalController
@onready var economy_controller: EconomyController = %EconomyController
@onready var easter_egg_controller: EasterEggController = %EasterEggController
@onready var environment_transition_controller: EnvironmentTransitionController = %EnvironmentTransitionController


func _physics_process(delta: float) -> void:
	player_movement_controller.move(delta)
	move_and_slide()
	player_movement_controller.handle_collisions()


func respawn(delay: float, target_transform: Transform3D, is_death: bool = false) -> void:
	ControlledEntityEvents.player_respawning.emit(delay)

	player_movement_controller.disable_movement(delay)
	velocity = Vector3.ZERO

	# Wait for the screen to fade in
	await get_tree().create_timer(delay).timeout

	global_position = target_transform.origin
	global_rotation.y = atan2(target_transform.basis.z.x, target_transform.basis.z.z)

	player_movement_controller.enable_movement()
	player_movement_controller.disable_movement(delay / 2.0)

	status_manager.clear_temporary_statuses()

	if is_death:
		health.reset()
		scale = Vector3.ONE

	input_controller.set_process_input(true)
	input_controller.set_process_unhandled_input(true)

	hitbox.set_deferred("monitoring", true)
	hitbox.set_deferred("monitorable", true)

	hurtbox.set_deferred("monitoring", true)
	hurtbox.set_deferred("monitorable", true)

	ControlledEntityEvents.player_finished_respawning.emit()
	# TODO This is needed because parent class unifies disable entity upon death for players and NPCs
	set_state(PlayerState.ACTIVE)


# TODO Maybe change this to a signal based to decouple?
## Re-applies when unchanged, respawn relies on it to undo disable_entity()
func set_state(new_state: PlayerState) -> void:
	state = new_state
	var is_active: bool = new_state == PlayerState.ACTIVE
	if is_active:
		ControlledEntityEvents.set_controlled_entity(self)
		add_to_group(Groups.CONTROLLED)
	else:
		remove_from_group(Groups.CONTROLLED)
	skills_controller.set_physics_process(is_active)
	set_collision_layer_value(1, is_active)
	collision_shape.set_deferred("disabled", not is_active)
	hurtbox.set_deferred("monitoring", is_active)
	hurtbox.set_deferred("monitorable", is_active)
	hitbox.set_deferred("monitoring", is_active)
	hitbox.set_deferred("monitorable", is_active)
	camera_controller.set_active(is_active)
	set_physics_process(is_active)
	visible = is_active


func _child_ready() -> void:
	add_to_group(Groups.PLAYERS)

	assert(player_save_controller != null, "Player save controller missing for " + name)

	ControlledEntityEvents.player_spawning.emit(self)

	input_controller.attack_pressed.connect(_on_attack_pressed)
	input_controller.return_to_checkpoint_requested.connect(_on_return_to_checkpoint_requested)

	health.damaged.connect(_on_damaged_vibration)
	# TODO Also disable input controller, player can attack between death and respawn
	health.died.connect(player_movement_controller.disable_movement.bind(INF))

	ApplicationStateManager.state_changed.connect(_on_application_state_changed)

	_on_application_state_changed(ApplicationStateManager.get_current_state(), ApplicationStateManager.get_previous_state())

	ControlledEntityEvents.player_finished_spawning.emit(self)


func finish_load() -> void:
	velocity = Vector3.ZERO
	player_movement_controller.enable_movement()


func _on_application_state_changed(new_state: ApplicationStateManager.GameState, _previous_state: ApplicationStateManager.GameState) -> void:
	# TODO Double check this
	if state == PlayerState.IN_VEHICLE:
		return
	set_state(PlayerState.ACTIVE if new_state == ApplicationStateManager.GameState.PLAYING else PlayerState.INACTIVE)


## Receives from input controller, goes to animation controller for attack
func _on_attack_pressed() -> void:
	melee_attacked.emit()


func _on_death_complete() -> void:
	economy_controller.remove_score(10)
	ControlledEntityEvents.request_respawn(2.0, CheckpointManager.get_respawn_transform(), true)


func _on_return_to_checkpoint_requested() -> void:
	if health.current_health <= 0:
		return
	ControlledEntityEvents.request_respawn(1.0, CheckpointManager.get_respawn_transform())


func _on_damaged_vibration(_attack: Attack) -> void:
	# TODO Change the gamepad index to the current player gamepad?
	Input.start_joy_vibration(0, 0.5, 0.5, 0.7)
