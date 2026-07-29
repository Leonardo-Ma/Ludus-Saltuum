# https://www.youtube.com/watch?v=5m7nBj98rx4 LegionGames - Race Car Controller Tutorial - Godot 3D
class_name PlayerCar
extends VehicleBody3D

signal driving_started(player: PlayerEntity)
signal driving_stopped(player: PlayerEntity)
signal teleported  # Back to checkpoint for example

const REENTER_CAR_DELAY: int = 10

#region Tuning
@export_category("Tuning")
@export_range(500.0, 8000.0, 100.0) var max_engine_force: float = 1800.0
## Approximate top speed in m/s
@export_range(20.0, 120.0, 1.0) var max_speed: float = 75.0
## Brake force while moving backward
@export_range(50.0, 500.0, 10.0) var max_brake_force: float = 220.0
## Brake force applied when not accelerating
@export_range(0.0, 30.0, 1.0) var coast_brake_force: float = 8.0
@export_range(1.0, 5.0, 0.1) var steering_speed: float = 2.0
## Steering angle at low speed
@export_range(0.1, 1.0, 0.01) var max_steering: float = 0.30
@export var reverse_engine_force: float = 1500.0
@export var reverse_max_speed: float = 20.0
@export_range(0.5, 5.0, 0.1) var reverse_speed_threshold: float = 1.0
#endregion

@export_category("Core")
@export var health: Health

var is_driven: bool = false

var initial_level_position: Transform3D

var _driver: PlayerEntity = null

@onready var enter_area: Area3D = %EnterArea

@onready var camera_anchor: Marker3D = %CameraAnchor
@onready var camera_pivot: Node3D = %CameraPivot
@onready var camera: Camera3D = %Camera3D
@onready var camera_look_at: Vector3 = global_position

@onready var front_left_wheel: VehicleWheel3D = %FrontLeftWheel
@onready var front_right_wheel: VehicleWheel3D = %FrontRightWheel
@onready var back_left_wheel: VehicleWheel3D = %BackLeftWheel
@onready var back_right_wheel: VehicleWheel3D = %BackRightWheel
## m/s?
@onready var speed_ratio: float


func _ready() -> void:
	initial_level_position = global_transform

	assert(enter_area != null, "EnterArea missing in " + name)
	assert(camera_anchor != null, "CameraAnchor missing in " + name)
	assert(camera_pivot != null, "CameraPivot missing in " + name)
	assert(camera != null, "Camera3D missing in " + name)

	assert(front_left_wheel != null, "FrontLeftWheel missing in " + name)
	assert(front_right_wheel != null, "FrontRightWheel missing in " + name)
	assert(back_left_wheel != null, "BackLeftWheel missing in " + name)
	assert(back_right_wheel != null, "BackRightWheel missing in " + name)

	enter_area.body_entered.connect(_on_enter_area_body_entered)

	set_physics_process(false)


func _physics_process(delta: float) -> void:
	assert(is_driven, "Car not driven in " + name)

	var forward: bool = Input.is_action_pressed("move_forward")
	var backward: bool = Input.is_action_pressed("move_backward")

	#var speed: float = linear_velocity.length()
	var forward_speed: float = -global_basis.z.dot(linear_velocity)

	var steering_input: float = Input.get_axis("move_right", "move_left")

	speed_ratio = clampf(absf(forward_speed) / max_speed, 0.0, 1.0)

	speed_ratio *= speed_ratio

	var steering_scale: float = lerpf(
		1.0,
		0.15,
		speed_ratio,
	)

	var target_steering: float = steering_input * max_steering * steering_scale

	steering = move_toward(
		steering,
		target_steering,
		steering_speed * delta,
	)

	if forward:
		var forward_scale: float = clampf(1.0 - forward_speed / max_speed, 0.0, 1.0)

		engine_force = max_engine_force * forward_scale
		brake = 0.0

	elif backward:
		var reverse_speed: float = maxf(-forward_speed, 0.0)
		var reverse_scale: float = clampf(1.0 - reverse_speed / reverse_max_speed, 0.0, 1.0)

		engine_force = -reverse_engine_force * reverse_scale
		brake = 0.0

	else:
		engine_force = 0.0
		brake = coast_brake_force

	var camera_pos_t: float = 1.0 - exp(-20.0 * delta)
	var camera_rot_t: float = 1.0 - exp(-5.0 * delta)

	camera_pivot.global_position = (camera_pivot.global_position.lerp(camera_anchor.global_position, camera_pos_t))

	camera_pivot.global_transform.basis = (camera_pivot.global_transform.basis.slerp(camera_anchor.global_transform.basis, camera_rot_t))

	var target: Vector3 = global_position + (global_basis.z * 10.0)

	camera_look_at = (camera_look_at.lerp(target, camera_rot_t))

	camera.look_at(camera_look_at)


func _on_enter_area_body_entered(body: Node3D) -> void:
	if (is_driven) or (body is not PlayerEntity):
		return
	_driver = body as PlayerEntity

	is_driven = true
	enter_area.set_deferred("monitoring", false)
	_driver.vehicle_rider.enter_vehicle()

	camera.current = true
	set_physics_process(true)
	set_process(true)
	driving_started.emit(_driver)
	GameEvents.set_controlled_entity(self)
	self.add_to_group(Groups.PLAYERS)


func exit(exit_position: Vector3) -> void:
	assert(is_driven, "Car not driven in " + name)

	set_physics_process(false)
	set_process(false)

	# TODO Add animation tween and fade out visual effect
	rotation = Vector3.ZERO
	engine_force = 0.0
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	global_transform = initial_level_position

	camera.current = false

	var driver: PlayerEntity = _driver
	_driver = null
	is_driven = false

	driver.vehicle_rider.exit_vehicle(exit_position)

	driving_stopped.emit(driver)
	self.remove_from_group(Groups.PLAYERS)

	await get_tree().create_timer(REENTER_CAR_DELAY).timeout
	enter_area.set_deferred("monitoring", true)


func respawn(delay: float, target_position: Vector3, is_death: bool = false) -> void:
	GameEvents.player_respawning.emit(delay)

	# Wait for the screen to fade in
	await get_tree().create_timer(delay / 2.0).timeout

	global_position = target_position

	rotation = Vector3.ZERO
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO

	teleported.emit()

	if is_death:
		health.reset()
		scale = Vector3.ONE
