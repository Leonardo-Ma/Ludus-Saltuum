class_name NPCMovementController
extends MovementComponent

## NOTE GOAP starts movement by requesting a route and cancels it with stop()
## Routes are checked against world collision before moving, blocked routes get a detour waypoint

const DETOUR_DIRECTIONS: int = 8
## Move direction dot wall normal at or below this counts as head-on
const HEAD_ON_DOT: float = -0.5
const MAX_SKIPPED_CHARACTERS: int = 4

const REACH_HORIZONTAL_TOLERANCE: float = 1.5
const REACH_VERTICAL_TOLERANCE: float = 4.0

@export_category("Pathfinding")
## Layers treated as route obstacles (World, World Object)
@export_flags_3d_physics var obstacle_mask: int = 9
## Height above route where obstacle rays are cast
@export_range(0.1, 2.0, 0.05, "suffix:m") var path_check_height: float = 0.5
## Distance from entity to detour candidates
@export_range(1.0, 20.0, 0.5, "suffix:m") var detour_distance: float = 4.0

var _final_target: Vector3 = Vector3.ZERO
var _desired_direction: Vector3 = Vector3.ZERO
var _safe_horizontal_velocity: Vector3 = Vector3.ZERO
var _has_route: bool = false
var _detour_active: bool = false
var _blocked: bool = false
var _requires_body_clearance: bool = false

@onready var _navigation_agent: NavigationAgent3D = %NavigationAgent3D
@onready var _character_owner: NPCEntity = owner


func _child_ready() -> void:
	assert(_navigation_agent, "NavigationAgent3D is missing in " + owner.name)
	assert(_character_owner, "NPCMovementController owner must be an NPCEntity in " + owner.name)

	_navigation_agent.velocity_computed.connect(_on_navigation_agent_3d_velocity_computed)
	_navigation_agent.target_reached.connect(_on_navigation_agent_3d_target_reached)
	_navigation_agent.navigation_finished.connect(_on_navigation_agent_3d_navigation_finished)


func _move(_delta: float) -> void:
	if not _can_follow_route():
		_stop_velocity()
		return

	if not _is_on_navigation_mesh():
		_stop_velocity()
		return

	if _detour_active and _navigation_agent.is_navigation_finished() and not _plan_route(_final_target, true, false):
		return

	var next_location: Vector3 = _navigation_agent.get_next_path_position()
	if _navigation_agent.is_navigation_finished():
		return

	var direction: Vector3 = next_location - _character_owner.global_position
	direction.y = 0.0
	_desired_direction = direction.normalized()

	if _navigation_agent.avoidance_enabled:
		_navigation_agent.set_velocity(_desired_direction * get_speed())
	movement_direction_changed.emit(Vector2(0, 1), 1.0)


## Direction of current route segment, before avoidance
func get_desired_direction() -> Vector3:
	return _desired_direction


func get_horizontal_velocity() -> Vector3:
	if _navigation_agent.avoidance_enabled:
		return _safe_horizontal_velocity
	return _desired_direction * get_speed()


## Replans around an obstacle reported by the body after sliding
func handle_route_obstruction() -> void:
	if _has_route:
		_plan_route(_final_target, true, true)


## Starts movement along a validated route to [param target], false if no route exists [br]
## With [param allow_detour] a blocked route is replaced by a waypoint route around the obstacle
func request_target(target: Vector3, allow_detour: bool) -> bool:
	if _requires_body_clearance:
		stop()
	if _detour_active:
		_final_target = target
		return true
	if _has_route and target.is_equal_approx(_final_target):
		return true
	return _plan_route(target, allow_detour, false)


## Request route with clearance for NPC body, including other characters
func request_clear_target(target: Vector3) -> bool:
	_requires_body_clearance = true
	return _plan_route(target, true, false)


## Request a reachable waypoint within radius of center
func request_nearby_target(center: Vector3, radius: float) -> bool:
	var map: RID = _navigation_agent.get_navigation_map()
	if radius <= 0.0 or not map.is_valid() or NavigationServer3D.map_get_iteration_id(map) == 0:
		return false
	var start_angle: float = randf() * TAU
	for step: int in DETOUR_DIRECTIONS:
		var angle: float = start_angle + TAU * step / DETOUR_DIRECTIONS
		var offset: Vector3 = Vector3(cos(angle), 0.0, sin(angle)) * randf_range(radius * 0.5, radius)
		var point: Vector3 = NavigationServer3D.map_get_closest_point(map, center + offset)
		if center.distance_to(point) > radius + _character_owner.safe_margin:
			continue
		if _character_owner.global_position.distance_to(point) <= _navigation_agent.target_desired_distance:
			continue
		_requires_body_clearance = true
		if _plan_route(point, false, false):
			return true
	return false


## True when last route request or movement found no way through
func is_blocked() -> bool:
	return _blocked


func has_route() -> bool:
	return _has_route


func is_navigation_finished() -> bool:
	return _has_route and not _detour_active and _navigation_agent.is_navigation_finished()


func is_target_reached() -> bool:
	return _navigation_agent.is_target_reached()


func is_target_reachable() -> bool:
	return _navigation_agent.is_target_reachable()


## False when target has no navmesh route or detour from current position, true while navmesh is not ready
func can_reach(target: Vector3) -> bool:
	var map: RID = _navigation_agent.get_navigation_map()
	if not map.is_valid() or NavigationServer3D.map_get_iteration_id(map) == 0:
		return true

	var origin: Vector3 = _character_owner.global_position
	var path: PackedVector3Array = NavigationServer3D.map_get_path(map, origin, target, true)
	if path.is_empty():
		return false

	var path_end: Vector3 = path[path.size() - 1]
	var horizontal_gap: float = Vector2(path_end.x, path_end.z).distance_to(Vector2(target.x, target.z))
	if horizontal_gap > REACH_HORIZONTAL_TOLERANCE or absf(path_end.y - target.y) > REACH_VERTICAL_TOLERANCE:
		return false

	return _is_path_clear(origin, target) or _find_detour(target).is_finite()


func stop() -> void:
	_requires_body_clearance = false
	_has_route = false
	_detour_active = false
	_stop_velocity()


func _plan_route(target: Vector3, allow_detour: bool, force_detour: bool) -> bool:
	var origin: Vector3 = _character_owner.global_position
	var waypoint: Vector3 = target
	_final_target = target
	_detour_active = false

	if force_detour or not _is_path_clear(origin, target, _requires_body_clearance):
		waypoint = _find_detour(target, _requires_body_clearance) if allow_detour else Vector3.INF
		_detour_active = waypoint.is_finite()

	_has_route = waypoint.is_finite()
	_blocked = not _has_route
	if _has_route:
		_navigation_agent.target_position = waypoint
	else:
		_stop_velocity()
	return _has_route


func _find_detour(target: Vector3, check_body_clearance: bool = false) -> Vector3:
	var map: RID = _navigation_agent.get_navigation_map()
	if not map.is_valid() or NavigationServer3D.map_get_iteration_id(map) == 0:
		return Vector3.INF
	var origin: Vector3 = _character_owner.global_position
	var best: Vector3 = Vector3.INF
	var best_length: float = INF

	for step: int in DETOUR_DIRECTIONS:
		var angle: float = TAU * step / DETOUR_DIRECTIONS
		var candidate: Vector3 = NavigationServer3D.map_get_closest_point(map, origin + Vector3(cos(angle), 0.0, sin(angle)) * detour_distance)
		var length: float = origin.distance_to(candidate) + candidate.distance_to(target)
		if (
			length < best_length and _is_path_clear(origin, candidate, check_body_clearance)
			and _is_path_clear(candidate, target, check_body_clearance)
		):
			best = candidate
			best_length = length

	return best


## Check navmesh route against world obstacles with optional body clearance
func _is_path_clear(from: Vector3, to: Vector3, check_body_clearance: bool = false) -> bool:
	var map: RID = _navigation_agent.get_navigation_map()
	if not map.is_valid() or NavigationServer3D.map_get_iteration_id(map) == 0:
		return false

	var path: PackedVector3Array = NavigationServer3D.map_get_path(map, from, to, true, _navigation_agent.navigation_layers)
	if path.is_empty():
		return false

	var space: PhysicsDirectSpaceState3D = _character_owner.get_world_3d().direct_space_state
	if check_body_clearance:
		if path[-1].distance_to(to) > _navigation_agent.target_desired_distance:
			return false
		return _has_body_clearance(space, path)
	var lift: Vector3 = Vector3.UP * path_check_height
	for index: int in range(1, path.size()):
		if not _is_segment_clear(space, path[index - 1] + lift, path[index] + lift):
			return false

	return true


func _has_body_clearance(space: PhysicsDirectSpaceState3D, path: PackedVector3Array) -> bool:
	var collider: CollisionShape3D = _character_owner.collision_shape
	var query: PhysicsShapeQueryParameters3D = PhysicsShapeQueryParameters3D.new()
	query.shape = collider.shape
	query.collision_mask = _character_owner.collision_mask | obstacle_mask
	query.exclude = [_character_owner.get_rid()]
	var offset: Vector3 = collider.global_position - _character_owner.global_position + Vector3.UP * _character_owner.safe_margin
	for index: int in path.size():
		query.transform = Transform3D(collider.global_basis, path[index] + offset)
		query.motion = Vector3.ZERO
		if not space.intersect_shape(query, 1).is_empty():
			return false
		if index + 1 < path.size():
			query.motion = path[index + 1] - path[index]
			if space.cast_motion(query)[0] < 1.0:
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


## Routes requiring body clearance may detour around blocking characters after local avoidance
func is_route_obstructed_by(normal: Vector3, character: bool = false) -> bool:
	if character and not _requires_body_clearance:
		return false
	var wall_normal: Vector3 = Vector3(normal.x, 0.0, normal.z)
	return not wall_normal.is_zero_approx() and _desired_direction.dot(wall_normal.normalized()) <= HEAD_ON_DOT


func _stop_velocity() -> void:
	var had_movement: bool = not _desired_direction.is_zero_approx() or not _safe_horizontal_velocity.is_zero_approx()
	_desired_direction = Vector3.ZERO
	_safe_horizontal_velocity = Vector3.ZERO
	if had_movement:
		if _navigation_agent.avoidance_enabled:
			_navigation_agent.set_velocity(Vector3.ZERO)
		movement_direction_changed.emit(Vector2.ZERO, 0.0)


func _can_follow_route() -> bool:
	return _has_route and movement_enabled and _disable_timer <= 0.0


# TODO Change speed to use a variable that is defined by goap action instead (both referencing movement resource instead)
func _on_navigation_agent_3d_velocity_computed(safe_velocity: Vector3) -> void:
	if not _can_follow_route() or _desired_direction.is_zero_approx():
		return

	_safe_horizontal_velocity = Vector3(safe_velocity.x, 0.0, safe_velocity.z)


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
