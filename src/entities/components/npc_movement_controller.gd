class_name NPCMovementController
extends MovementComponent

## NOTE If this is used by GOAP, it will be disabled and enabled depending on current action
## Routes are checked against world collision before moving, blocked routes get a detour waypoint

const DETOUR_DIRECTIONS: int = 8
## Move direction dot wall normal at or below this counts as head-on
const HEAD_ON_DOT: float = -0.5
const MAX_SKIPPED_CHARACTERS: int = 4

@export_category("Pathfinding")
## Layers treated as route obstacles (World, World Object)
@export_flags_3d_physics var obstacle_mask: int = 9
## Height above route where obstacle rays are cast
@export_range(0.1, 2.0, 0.05, "suffix:m") var path_check_height: float = 0.5
## Distance from entity to detour candidates
@export_range(1.0, 20.0, 0.5, "suffix:m") var detour_distance: float = 4.0

var _final_target: Vector3 = Vector3.ZERO
var _desired_direction: Vector3 = Vector3.ZERO
var _has_route: bool = false
var _detour_active: bool = false
var _blocked: bool = false

@onready var _navigation_agent: NavigationAgent3D = %NavigationAgent3D
@onready var _character_owner: NPCEntity = owner


func _child_ready() -> void:
	assert(_navigation_agent, "NavigationAgent3D is missing in " + owner.name)
	assert(_character_owner, "NPCMovementController owner must be an NPCEntity in " + owner.name)

	_navigation_agent.velocity_computed.connect(_on_navigation_agent_3d_velocity_computed)
	_navigation_agent.target_reached.connect(_on_navigation_agent_3d_target_reached)
	_navigation_agent.navigation_finished.connect(_on_navigation_agent_3d_navigation_finished)

	# Start disabled by default for GOAP to control
	set_physics_process(false)


func _move(delta: float) -> void:
	if not is_physics_processing() or not movement_enabled or _disable_timer > 0.0 or not _has_route:
		_stop_velocity()
		return

	if not _is_on_navigation_mesh():
		_stop_velocity()
		return

	if _detour_active and _navigation_agent.is_navigation_finished() and not _plan_route(_final_target, true, false):
		stop()
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

	_desired_direction = direction

	var move_speed: float = get_speed()
	var new_velocity: Vector3 = direction * move_speed

	if not _character_owner.is_on_floor():
		new_velocity.y = _character_owner.velocity.y + _character_owner.get_gravity().y * gravity_multiplier * delta

	if _navigation_agent.avoidance_enabled:
		_navigation_agent.set_velocity(new_velocity)
		movement_direction_changed.emit(Vector2(0, 1), 1.0)
	else:
		_character_owner.velocity = new_velocity
		movement_direction_changed.emit(Vector2(0, 1), 1.0)


func handle_collisions() -> void:
	super()
	if _has_route and _is_blocked_by_wall() and not _plan_route(_final_target, true, true):
		stop()


## Validates route to [param target] before moving, false when blocked and no way through exists [br]
## With [param allow_detour] a blocked route is replaced by a waypoint route around the obstacle
func request_target(target: Vector3, allow_detour: bool) -> bool:
	if _detour_active:
		_final_target = target
		return true
	if _has_route and target.is_equal_approx(_final_target):
		return true
	return _plan_route(target, allow_detour, false)


## True when last route request or movement found no way through
func is_blocked() -> bool:
	return _blocked


func is_navigation_finished() -> bool:
	return _has_route and not _detour_active and _navigation_agent.is_navigation_finished()


func is_target_reached() -> bool:
	return _navigation_agent.is_target_reached()


func is_target_reachable() -> bool:
	return _navigation_agent.is_target_reachable()


func stop() -> void:
	set_physics_process(false)
	_has_route = false
	_detour_active = false
	_stop_velocity()
	_navigation_agent.set_velocity(Vector3.ZERO)


func _plan_route(target: Vector3, allow_detour: bool, force_detour: bool) -> bool:
	var origin: Vector3 = _character_owner.global_position
	var waypoint: Vector3 = target
	_final_target = target
	_detour_active = false

	if force_detour or not _is_path_clear(origin, target):
		waypoint = _find_detour(target) if allow_detour else Vector3.INF
		_detour_active = waypoint.is_finite()

	_has_route = waypoint.is_finite()
	_blocked = not _has_route
	if _has_route:
		_set_agent_target(waypoint)
	return _has_route


func _find_detour(target: Vector3) -> Vector3:
	var map: RID = _navigation_agent.get_navigation_map()
	var origin: Vector3 = _character_owner.global_position
	var best: Vector3 = Vector3.INF
	var best_length: float = INF

	for step: int in DETOUR_DIRECTIONS:
		var angle: float = TAU * step / DETOUR_DIRECTIONS
		var candidate: Vector3 = NavigationServer3D.map_get_closest_point(map, origin + Vector3(cos(angle), 0.0, sin(angle)) * detour_distance)
		var length: float = origin.distance_to(candidate) + candidate.distance_to(target)
		if length < best_length and _is_path_clear(origin, candidate) and _is_path_clear(candidate, target):
			best = candidate
			best_length = length

	return best


## Navmesh path exists and no obstacle ray hits along it, characters are not obstacles
func _is_path_clear(from: Vector3, to: Vector3) -> bool:
	var map: RID = _navigation_agent.get_navigation_map()
	if not map.is_valid() or NavigationServer3D.map_get_iteration_id(map) == 0:
		return false

	var path: PackedVector3Array = NavigationServer3D.map_get_path(map, from, to, true)
	if path.is_empty():
		return false

	var space: PhysicsDirectSpaceState3D = _character_owner.get_world_3d().direct_space_state
	var lift: Vector3 = Vector3.UP * path_check_height
	for index: int in range(1, path.size()):
		if not _is_segment_clear(space, path[index - 1] + lift, path[index] + lift):
			return false

	return true


## Ray re-cast past character bodies, so a wall behind a character still blocks
func _is_segment_clear(space: PhysicsDirectSpaceState3D, from: Vector3, to: Vector3) -> bool:
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(from, to, obstacle_mask)
	var excluded: Array[RID] = [_character_owner.get_rid()]

	for _attempt: int in MAX_SKIPPED_CHARACTERS + 1:
		query.exclude = excluded
		var hit: Dictionary = space.intersect_ray(query)
		if hit.is_empty():
			return true
		var character: CharacterBody3D = hit.collider as CharacterBody3D
		if character == null:
			return false
		excluded.append(character.get_rid())

	return false


## Static or rigid obstacle opposing movement, other characters are left to avoidance
func _is_blocked_by_wall() -> bool:
	if _desired_direction.is_zero_approx():
		return false

	for index: int in _character_owner.get_slide_collision_count():
		var collision: KinematicCollision3D = _character_owner.get_slide_collision(index)
		if collision.get_collider() is CharacterBody3D or collision.get_angle() <= _character_owner.floor_max_angle:
			continue
		var wall_normal: Vector3 = collision.get_normal()
		wall_normal.y = 0.0
		if not wall_normal.is_zero_approx() and _desired_direction.dot(wall_normal.normalized()) <= HEAD_ON_DOT:
			return true

	return false


func _set_agent_target(target_location: Vector3) -> void:
	if not _navigation_agent.target_position.is_equal_approx(target_location):
		_navigation_agent.target_position = target_location


func _stop_velocity() -> void:
	_desired_direction = Vector3.ZERO
	_character_owner.velocity.x = 0.0
	_character_owner.velocity.z = 0.0
	movement_direction_changed.emit(Vector2.ZERO, 0.0)


# TODO Change speed to use a variable that is defined by goap action instead (both referencing movement resource instead)
func _on_navigation_agent_3d_velocity_computed(safe_velocity: Vector3) -> void:
	if not is_physics_processing() or not movement_enabled or _disable_timer > 0.0:
		return

	_character_owner.velocity.x = safe_velocity.x
	_character_owner.velocity.z = safe_velocity.z


func _on_navigation_agent_3d_target_reached() -> void:
	_stop_velocity()


func _on_navigation_agent_3d_navigation_finished() -> void:
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

	return horizontal_distance < 10.0 and vertical_distance < 10.0
