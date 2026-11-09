class_name NPCMovementController
extends EntityMovementController

## NOTE If this is used by GOAP, it will be disabled and enabled depending on current action

@onready var _navigation_agent: NavigationAgent3D = %NavigationAgent3D
@onready var _character_owner: NPCEntity = owner


func _child_ready() -> void:
	assert(_navigation_agent != null, "NavigationAgent3D is missing in " + owner.name)
	assert(_character_owner != null, "NPCMovementController owner must be an NPCEntity in " + owner.name)
	_navigation_agent.velocity_computed.connect(_on_navigation_agent_3d_velocity_computed)
	_navigation_agent.target_reached.connect(_on_navigation_agent_3d_target_reached)
	# Start disabled by default for GOAP to control
	set_physics_process(false)


func _move(delta: float) -> void:
	if not is_physics_processing() or not movement_enabled or _disable_timer > 0.0:
		_stop_velocity()
		return

	if _navigation_agent.is_navigation_finished() or not _is_on_navigation_mesh():
		_stop_velocity()
		return

	var next_location: Vector3 = _navigation_agent.get_next_path_position()
	var direction: Vector3 = next_location - _character_owner.global_position
	direction.y = 0.0
	direction = direction.normalized()

	if direction.length_squared() > 0.001:
		direction = direction.normalized()
		var target_rotation_y: float = atan2(direction.x, direction.z)
		var rotation_speed: float = 10
		_character_owner.global_rotation.y = lerp_angle(_character_owner.global_rotation.y, target_rotation_y, 1.0 - exp(-rotation_speed * delta))

	var move_speed: float = _movement.get_speed()
	var new_velocity: Vector3 = direction * move_speed

	if not _character_owner.is_on_floor():
		new_velocity.y = _character_owner.velocity.y + _character_owner.get_gravity().y * _movement.gravity_multiplier * delta

	if _navigation_agent.avoidance_enabled:
		_navigation_agent.set_velocity(new_velocity)
	else:
		_character_owner.velocity = new_velocity


func update_target_location(target_location: Vector3) -> void:
	if not _navigation_agent.target_position.is_equal_approx(target_location):
		_navigation_agent.target_position = target_location


func stop() -> void:
	set_physics_process(false)
	_stop_velocity()
	_navigation_agent.set_velocity(Vector3.ZERO)


func _stop_velocity() -> void:
	_character_owner.velocity.x = 0.0
	_character_owner.velocity.z = 0.0


# TODO Change speed to use a variable that is defined by goap action instead (both referencing movement resource instead)
func _on_navigation_agent_3d_velocity_computed(safe_velocity: Vector3) -> void:
	if not is_physics_processing() or not movement_enabled or _disable_timer > 0.0:
		return

	_character_owner.velocity.x = safe_velocity.x
	_character_owner.velocity.z = safe_velocity.z


func _on_navigation_agent_3d_target_reached() -> void:
	_stop_velocity()


func _is_on_navigation_mesh() -> bool:
	var map: RID = _navigation_agent.get_navigation_map()

	if not map.is_valid() or NavigationServer3D.map_get_iteration_id(map) == 0:
		return false

	var closest_point: Vector3 = NavigationServer3D.map_get_closest_point(map, _character_owner.global_position)
	var horizontal_distance: float = Vector2(_character_owner.global_position.x, _character_owner.global_position.z).distance_to(
		Vector2(closest_point.x, closest_point.z)
	)
	var vertical_distance: float = absf(_character_owner.global_position.y - closest_point.y)

	return horizontal_distance < 2.0 and vertical_distance < 3.0
