class_name PlayerEntity
extends AggressiveEntity

@export_category("Skills")
@export var startup_skill_ids: Array[StringName] = []

@onready var camera_controller: CameraController = %CamRoot
@onready var movement_controller: MovementController = %MovementController
@onready var input_controller: InputController = %InputController
@onready var skills_controller: SkillsController = %SkillsController

@onready var vehicle_rider: VehicleRider = %VehicleRider
@onready var portal_controller: PortalController = %PortalController


func _physics_process(delta: float) -> void:
	if portal_controller._portal_transitioning:  # If mid teleport
		move_and_slide()
		return

	movement_controller.move(self, delta)
	move_and_slide()

	# Apply physics collision with rigid bodies
	for i: int in get_slide_collision_count():
		var collision: KinematicCollision3D = get_slide_collision(i)
		var collider: Object = collision.get_collider()
		if collider is RigidBody3D:
			var push_force: float = movement.speed * 0.1
			var push_dir: Vector3 = -collision.get_normal()
			push_dir.y = 0.0  # Prevent pushing into the ground or sky
			if push_dir.length_squared() > 0.001:
				collider.apply_impulse(push_dir.normalized() * push_force, collision.get_position() - collider.global_position)


func _child_ready() -> void:
	add_to_group(Groups.PLAYERS)
	GameEvents.player_spawned.emit(self)
	GameEvents.set_controlled_entity(self)

	input_controller.attack_pressed.connect(_on_attack_pressed)
	input_controller.return_to_checkpoint_requested.connect(_on_return_to_checkpoint_requested)

	health.damaged.connect(_on_damaged_vibration)
	# TODO Also disable input controller, player can attack between death and respawn
	health.died.connect(movement_controller.disable_movement.bind(5.0))


## Receives from input controller, goes to animation controller for attack
func _on_attack_pressed() -> void:
	melee_attacked.emit()


func _on_death_complete() -> void:
	GameEvents.remove_score(10)
	await respawn(2.0, CheckpointManager.get_respawn_position(), true)


func respawn(delay: float, target_position: Vector3, is_death: bool = false) -> void:
	GameEvents.player_respawning.emit(delay)

	movement_controller.disable_movement(delay)
	velocity = Vector3.ZERO

	# Wait for the screen to fade in
	await get_tree().create_timer(delay / 2.0).timeout

	GameEvents.controlled_entity.global_position = target_position

	if is_death:
		health.reset()
		status_manager.clear_temporary_statuses()
		scale = Vector3.ONE

	input_controller.set_process_input(true)
	input_controller.set_process_unhandled_input(true)

	hitbox.set_deferred("monitoring", true)
	hitbox.set_deferred("monitorable", true)

	hurtbox.set_deferred("monitoring", true)
	hurtbox.set_deferred("monitorable", true)


func _on_return_to_checkpoint_requested() -> void:
	if health.current_health <= 0:
		return
	await respawn(1.0, CheckpointManager.get_respawn_position())


func _on_damaged_vibration(_attack: Attack) -> void:
	# TODO Change the gamepad index to the current player gamepad?
	Input.start_joy_vibration(0, 0.5, 0.5, 0.7)


func entity_enable_disable(toggle: bool) -> void:
	skills_controller.set_physics_process(toggle)
	set_collision_layer_value(1, toggle)
	hurtbox.set_deferred("monitoring", toggle)
	hurtbox.set_deferred("monitorable", toggle)
	hitbox.set_deferred("monitoring", toggle)
	hitbox.set_deferred("monitorable", toggle)
	camera_controller.set_active(toggle)
	set_physics_process(toggle)
	visible = toggle


func begin_portal_transition(source: TeleportPortal, destination: TeleportPortal) -> void:
	await portal_controller.begin_portal_transition(source, destination, self)
