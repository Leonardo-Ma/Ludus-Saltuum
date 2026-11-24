@abstract class_name MovementComponent
extends Node3D

## Abstract base component handling entity movement and physics collisions through its owner

# These signals go to animation controller, debug...
signal movement_direction_changed(direction: Vector2, speed_factor: float)

@export var movement: Movement

var movement_enabled: bool = true

## Runtime bonuses and multipliers
var speed_bonus: float = 0.0
var speed_multiplier: float = 1.0
var gravity_multiplier: float = 1.0
var jump_bonus: float = 0.0
var jump_multiplier: float = 1.0
## Applied to gravity only while falling
var fall_gravity_multiplier: float = 1.0

var _disable_timer: float = 0.0
var _external_force: Vector3 = Vector3.ZERO


## Children must override this instead of _ready()
@abstract func _child_ready() -> void


## Children must override [br]
## Core movement logic for movement controllers executed each physics frame by owner
@abstract func _move(delta: float) -> void


func _ready() -> void:
	assert(movement != null, "Movement missing for " + owner.name)
	_child_ready()


func get_speed() -> float:
	return (movement.speed + speed_bonus) * speed_multiplier


func get_jump_velocity() -> float:
	return (movement.jump_velocity + jump_bonus) * jump_multiplier


## Executed by entity's _physics_process
func move(delta: float) -> void:
	_update_disable_timer(delta)
	_move(delta)


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


## Returns and clears accumulated external force for this physics step
func consume_external_force() -> Vector3:
	var force: Vector3 = _external_force
	_external_force = Vector3.ZERO
	return force
