class_name InvestigateAction
extends GoapAction

## Sweep for enemies while walking between reachable points around latest evidence

const SCAN_SPEED: float = PI / 3.0
var _destination: Vector3 = Vector3.INF
var _reachable_center: Vector3 = Vector3.INF
var _waiting_for_route: bool = false


func get_custom_class_name() -> String:
	return "InvestigateAction"


func is_valid(_blackboard: Dictionary) -> bool:
	return _blackboard[GoapKeys.HAS_INVESTIGATION_POINT] and not _blackboard[GoapKeys.IN_COMBAT] and not _blackboard[GoapKeys.LOW_HEALTH]


func get_preconditions() -> Dictionary:
	return { GoapKeys.HAS_INVESTIGATION_POINT: true }


func get_effects() -> Dictionary:
	return { GoapKeys.IS_INVESTIGATING: true }


func perform(_actor: Node, _delta: float, _blackboard: Dictionary) -> bool:
	var entity: NPCEntity = _actor
	var perception: PerceptionSystem = entity.perception_system
	var movement: NPCMovementController = entity.npc_movement_controller
	if not perception.has_investigation_point():
		return true
	if perception.investigation_position != _destination:
		if _destination == Vector3.INF:
			perception.share_investigation()
		perception.sight_yaw_offset = 0.0
		movement.stop()
		_destination = perception.investigation_position
		_reachable_center = Vector3.INF
		_waiting_for_route = false
		movement.request_clear_target(_destination)
	perception.sight_yaw_offset += SCAN_SPEED * _delta
	var sweep_complete: bool = perception.sight_yaw_offset >= TAU
	perception.sight_yaw_offset = fmod(perception.sight_yaw_offset, TAU)
	if movement.has_route() and not movement.is_navigation_finished():
		return false
	if not _waiting_for_route or sweep_complete:
		var radius: float = perception.config.investigation_radius
		_waiting_for_route = not movement.request_nearby_target(_destination, radius)
		if _waiting_for_route and radius > 0.0:
			if _reachable_center == Vector3.INF:
				_reachable_center = entity.global_position
			if not _reachable_center.is_equal_approx(_destination):
				_waiting_for_route = not movement.request_nearby_target(_reachable_center, radius)
	return false


func exit(_actor: Node) -> void:
	var entity: NPCEntity = _actor
	entity.npc_movement_controller.stop()
	entity.perception_system.sight_yaw_offset = 0.0
	_destination = Vector3.INF
