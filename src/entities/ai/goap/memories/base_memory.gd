# TODO Consider transforming into a resource
# TODO This is quite outdated and long gone, need rename and double check. This is the template?
class_name BaseMemory
extends GoapMemory

const HEALTH_LOW_THRESHOLD: float = 0.3
const MELEE_RANGE_SQUARED: float = 1.44 # 1.2 * 1.2
const NEARBY_RANGE: float = 15.0

var _search_target: KnownEntityData
var _search_position: Vector3


func init(actor: Node) -> void:
	_actor = actor
	var entity: NPCEntity = _actor
	assert(entity != null, "BaseMemory: actor must be NPCEntity in " + name)
	entity.health.damaged.connect(
		func(_attack: Attack) -> void:
			force_refresh_blackboard(),
	)

	_blackboard = {
		GoapKeys.POSITION: _actor.position,
		GoapKeys.ENEMY_ALIVE: false,
		GoapKeys.ENEMY_NEARBY: false,
		GoapKeys.ENEMY_IN_MELEE_RANGE: false,
		GoapKeys.ENEMY_IN_RANGED_RANGE: false,
		GoapKeys.ENEMY_POSITION: Vector3(),
		GoapKeys.IN_COMBAT: false,
		GoapKeys.LOW_HEALTH: false,
		GoapKeys.IS_WANDERING: false,
		GoapKeys.ENEMY_REACHABLE: true,
		GoapKeys.HAS_INVESTIGATION_POINT: false,
		GoapKeys.INVESTIGATION_POSITION: Vector3(),
		GoapKeys.IS_INVESTIGATING: false,
	}


func _get_health_percentage() -> float:
	var health: HealthComponent = (_actor as NPCEntity).health
	if health == null or health.max_health <= 0:
		return 1.0

	return float(health.current_health) / health.max_health


func _is_low_health() -> bool:
	return _get_health_percentage() <= HEALTH_LOW_THRESHOLD


func _refresh_blackboard() -> void:
	if not is_instance_valid(_actor):
		return

	var entity: NPCEntity = _actor
	var perception: PerceptionSystem = entity.perception_system
	if not perception:
		push_warning("Perception missing for " + _actor.name)
		return

	var best_target_data: KnownEntityData = perception.get_best_target_data()
	var current_time: float = Time.get_ticks_msec() / 1000.0
	var actor_pos: Vector3 = _actor.global_position
	var low_health: bool = _is_low_health()
	var proj_component: ProjectileAttackComponent = entity.projectile_attack_component
	var projectile_attack: ProjectileAttack = proj_component.projectile_attack if proj_component != null else null

	# Ranged NPCs flee until beyond their own max range
	var nearby_range: float = maxf(NEARBY_RANGE, projectile_attack.max_range) if projectile_attack else NEARBY_RANGE
	var remembered_threat_nearby: bool = false

	# If active line of sight (seen in the last 0.5 seconds), track exactly
	# Prevents tracking stutter caused by the perception update interval rate
	# Otherwise target is lost and its last known position becomes the place to search
	if best_target_data and current_time - best_target_data.last_detection_time >= PerceptionSystem.VISUAL_TRACK_DURATION:
		_report_search_target(perception, best_target_data)
		if low_health:
			_blackboard[GoapKeys.ENEMY_POSITION] = best_target_data.last_known_position
			remembered_threat_nearby = actor_pos.distance_squared_to(best_target_data.last_known_position) < nearby_range * nearby_range
		best_target_data = null

	if not best_target_data:
		_blackboard[GoapKeys.POSITION] = actor_pos
		_blackboard[GoapKeys.ENEMY_IN_MELEE_RANGE] = false
		_blackboard[GoapKeys.ENEMY_IN_RANGED_RANGE] = false
		_blackboard[GoapKeys.ENEMY_NEARBY] = remembered_threat_nearby
		_blackboard[GoapKeys.ENEMY_ALIVE] = false
		_blackboard[GoapKeys.ENEMY_REACHABLE] = true
		_blackboard[GoapKeys.IN_COMBAT] = false
		_blackboard[GoapKeys.LOW_HEALTH] = low_health
		_blackboard[GoapKeys.IS_WANDERING] = false
		_write_investigation(perception)
		return

	var current_target: Node3D = best_target_data.entity
	assert(current_target != null, "Target entity is missing from target data")
	assert("health" in current_target and current_target.health != null, "Target must have a valid Health resource.")

	var enemy_pos: Vector3 = current_target.global_position
	var distance_squared: float = actor_pos.distance_squared_to(enemy_pos)

	# BUG In order for this to work it has to be same
	# target desired distance of NavigationAgent3D
	var in_melee_range: bool = distance_squared <= MELEE_RANGE_SQUARED
	var enemy_nearby: bool = distance_squared < nearby_range * nearby_range
	var enemy_alive: bool = current_target.health.current_health > 0.0
	var enemy_reachable: bool = entity.npc_movement_controller.can_reach(enemy_pos)

	var in_ranged_range: bool = projectile_attack != null and distance_squared <= projectile_attack.max_range * projectile_attack.max_range
	var in_combat: bool = (in_melee_range or in_ranged_range) and enemy_alive

	# Seen but far or unreachable, search toward it instead of idling
	if enemy_nearby and enemy_reachable:
		_search_target = null
		perception.clear_investigation_point()
	else:
		_report_search_target(perception, best_target_data)

	_blackboard[GoapKeys.ENEMY_POSITION] = enemy_pos
	_blackboard[GoapKeys.POSITION] = actor_pos
	_blackboard[GoapKeys.ENEMY_IN_MELEE_RANGE] = in_melee_range
	_blackboard[GoapKeys.ENEMY_NEARBY] = enemy_nearby
	_blackboard[GoapKeys.ENEMY_ALIVE] = enemy_alive
	_blackboard[GoapKeys.ENEMY_REACHABLE] = enemy_reachable
	_blackboard[GoapKeys.ENEMY_IN_RANGED_RANGE] = in_ranged_range
	_blackboard[GoapKeys.IN_COMBAT] = in_combat
	_blackboard[GoapKeys.LOW_HEALTH] = low_health
	_blackboard[GoapKeys.IS_WANDERING] = false
	_write_investigation(perception)


## Refreshing memory must not restart a completed search at same location
func _report_search_target(perception: PerceptionSystem, target: KnownEntityData) -> void:
	if target == _search_target and target.last_known_position.is_equal_approx(_search_position):
		return
	_search_target = target
	_search_position = target.last_known_position
	perception.report_last_sighting(target)


func _write_investigation(perception: PerceptionSystem) -> void:
	_blackboard[GoapKeys.HAS_INVESTIGATION_POINT] = perception.has_investigation_point()
	_blackboard[GoapKeys.INVESTIGATION_POSITION] = perception.investigation_position
	_blackboard[GoapKeys.IS_INVESTIGATING] = false
