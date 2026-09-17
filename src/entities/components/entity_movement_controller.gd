@abstract class_name EntityMovementController
extends Node3D

# These signals go to animation controller, debug...
signal movement_direction_changed(direction: Vector2, speed_factor: float)

var movement_enabled: bool = true

var _disable_timer: float = 0.0
var _external_force: Vector3 = Vector3.ZERO

@onready var _movement: Movement = owner.movement


## Children must override this instead of _ready()
@abstract func _child_ready() -> void


## Children must override [br]
## Core movement logic for movement controllers that will be executed each physics frame by owner
@abstract func _move(delta: float) -> void


func _ready() -> void:
	assert(_movement != null, "Movement missing for " + owner.name)
	_child_ready()


## This is executed by entity's _physics_process
func move(delta: float) -> void:
	_update_disable_timer(delta)
	_move(delta)
	_apply_external_force()


## After move_and_slide, called by entity
func handle_collisions() -> void:
	for i: int in owner.get_slide_collision_count():
		var collision: KinematicCollision3D = owner.get_slide_collision(i)
		var collider: Object = collision.get_collider()
		if collider is RigidBody3D:
			var push_force: float = _movement.speed * 0.1
			var push_dir: Vector3 = -collision.get_normal()
			# Push down or sideways, never up
			if push_dir.y > 0.0:
				push_dir.y = 0.0
			if not push_dir.is_zero_approx():
				(collider as RigidBody3D).apply_central_impulse(push_dir.normalized() * push_force)


func disable_movement(duration: float) -> void:
	movement_enabled = false
	_disable_timer = maxf(_disable_timer, duration)
	movement_direction_changed.emit(Vector2.ZERO, 0.0)


func enable_movement() -> void:
	movement_enabled = true
	_disable_timer = 0.0


## Called by external systems (wind, hazards...) to add continuous push force this frame
func add_external_force(force: Vector3) -> void:
	_external_force += force


func _update_disable_timer(delta: float) -> void:
	if _disable_timer <= 0.0:
		return

	_disable_timer -= delta

	if _disable_timer <= 0.0:
		movement_enabled = true


func _apply_external_force() -> void:
	if _external_force != Vector3.ZERO:
		owner.velocity += _external_force
		_external_force = Vector3.ZERO
