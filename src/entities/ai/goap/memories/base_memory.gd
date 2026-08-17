# TODO Consider transforming into a resource
# TODO This is quite outdated and long gone, need rename and double check. This is the template?
class_name BaseMemory
extends GoapMemory

const HEALTH_LOW_THRESHOLD: float = 0.3
const MELEE_RANGE_SQUARED: float = 1.44  # 1.2 * 1.2
const NEARBY_RANGE_SQUARED: float = 225.0  # 15.0 * 15.0


func init(actor: Node) -> void:
	_actor = actor

	_blackboard = {
		"position": _actor.position,
		"enemy_alive": false,
		"enemy_nearby": false,
		"enemy_in_melee_range": false,
		"enemy_position": Vector3(),
		"in_combat": false,
		"low_health": false,
		"is_wandering": false
	}


func _get_health() -> Variant:
	if _actor.has_method("get_health"):
		return _actor.get_health()

	if "health" in _actor:
		return _actor.get("health")

	return null


func _get_health_percentage() -> float:
	var health: Variant = _get_health()
	if health == null:
		return 1.0
	return health.current_health / health.max_health


func _is_low_health() -> bool:
	return _get_health_percentage() <= HEALTH_LOW_THRESHOLD


func update_blackboard() -> void:
	if not is_instance_valid(_actor):
		return

	var perception: PerceptionSystem = _actor.get("perception_system")
	if not perception:
		return

	var best_target_data: KnownEntityData = perception.get_best_target_data()

	var actor_pos: Vector3 = _actor.global_position

	if not best_target_data:
		_blackboard["position"] = actor_pos
		_blackboard["enemy_in_melee_range"] = false
		_blackboard["enemy_nearby"] = false
		_blackboard["enemy_alive"] = false
		_blackboard["in_combat"] = false
		_blackboard["low_health"] = _is_low_health()
		_blackboard["is_wandering"] = false
		return

	var current_target: Node3D = best_target_data.entity
	assert(current_target != null, "Target entity is missing from target data")
	assert("health" in current_target and current_target.health != null, "Target must have a valid Health resource.")

	var current_time: float = Time.get_ticks_msec() / 1000.0
	var enemy_pos: Vector3 = best_target_data.last_known_position

	# If active line of sight (seen in the last 0.5 seconds), track exactly
	# Prevents tracking stutter caused by the perception update interval rate
	if current_time - best_target_data.last_detection_time < 0.5:
		enemy_pos = current_target.global_position

	var distance_to_last_known_squared: float = actor_pos.distance_squared_to(enemy_pos)
	var true_distance_squared: float = actor_pos.distance_squared_to(current_target.global_position)

	# BUG In order for this to work it has to be same
	# target desired distance of NavigationAgent3D
	var in_melee_range: bool = true_distance_squared <= MELEE_RANGE_SQUARED
	var enemy_nearby: bool = distance_to_last_known_squared < NEARBY_RANGE_SQUARED

	var enemy_alive: bool = current_target.health.current_health > 0.0
	var in_combat: bool = in_melee_range and enemy_alive

	_blackboard["enemy_position"] = enemy_pos
	_blackboard["position"] = actor_pos
	_blackboard["enemy_in_melee_range"] = in_melee_range
	_blackboard["enemy_nearby"] = enemy_nearby
	_blackboard["enemy_alive"] = enemy_alive
	_blackboard["in_combat"] = in_combat
	_blackboard["low_health"] = _is_low_health()
	_blackboard["is_wandering"] = false
