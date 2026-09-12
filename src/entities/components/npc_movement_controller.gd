# If this is used by GOAP, it will be disabled and enabled depending on current action
# https://www.youtube.com/watch?v=-juhGgA076E DevLogLogan Godot 4 3D - AI Pathfinding/Navigation
# TODO Maybe assert instead of if != null?
class_name NPCMovementController
extends EntityMovementController

@onready var _navigation_agent: NavigationAgent3D = %NavigationAgent3D
@onready var _character_owner: AggressiveEntity = owner as AggressiveEntity


func _child_ready() -> void:
	assert(_navigation_agent != null, "NavigationAgent3D is missing in " + owner.name)
	assert(_character_owner != null, "NPCMovementController owner must be an AggressiveEntity in " + owner.name)
	_navigation_agent.velocity_computed.connect(_on_navigation_agent_3d_velocity_computed)
	_navigation_agent.target_reached.connect(_on_navigation_agent_3d_target_reached)
	# Start disabled by default for GOAP to control
	set_physics_process(false)


# TODO Check better approach than ignores
@warning_ignore("unused_parameter") # gdlint-ignore-next-line unused-argument
func _move(_delta: float) -> void:
	if _navigation_agent.is_navigation_finished():
		stop()
		return
	var next_location: Vector3 = _navigation_agent.get_next_path_position()
	var direction: Vector3 = _character_owner.global_position.direction_to(next_location)
	direction.y = 0.0
	direction = direction.normalized()
	var new_velocity: Vector3 = direction * _movement.speed
	if direction.length_squared() > 0.001:
		var target_rotation_y: float = atan2(direction.x, direction.z)
		_character_owner.global_rotation.y = lerp_angle(_character_owner.global_rotation.y, target_rotation_y, 0.15)
	_navigation_agent.set_velocity(new_velocity)


func update_target_location(target_location: Vector3) -> void:
	if not _navigation_agent.target_position.is_equal_approx(target_location):
		_navigation_agent.target_position = target_location


func stop() -> void:
	set_physics_process(false)
	_character_owner.velocity = Vector3.ZERO
	_navigation_agent.set_velocity(Vector3.ZERO)
	movement_direction_changed.emit(Vector2.ZERO, 0.0)


# TODO Change speed to use a variable that is defined by goap action instead (both referencing movement resource instead)
func _on_navigation_agent_3d_velocity_computed(safe_velocity: Vector3) -> void:
	if not is_physics_processing() or _disable_timer > 0.0:
		return

	_character_owner.velocity = safe_velocity
	# NPCs using navigation typically move forward locally.
	movement_direction_changed.emit(Vector2(0, 1), 1.0)


func _on_navigation_agent_3d_target_reached() -> void:
	_character_owner.velocity = Vector3.ZERO
	movement_direction_changed.emit(Vector2.ZERO, 0.0)
