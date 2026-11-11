class_name FleeFromEnemy
extends GoapAction


func get_custom_class_name() -> String:
	return "FleeFromEnemy"


func is_valid(_blackboard: Dictionary) -> bool:
	return _blackboard[GoapKeys.LOW_HEALTH] == true


func get_cost(_blackboard: Dictionary) -> int:
	return 1


func get_preconditions() -> Dictionary:
	return { GoapKeys.ENEMY_NEARBY: true, GoapKeys.LOW_HEALTH: true }


func get_effects() -> Dictionary:
	return { GoapKeys.ENEMY_NEARBY: false }


# TODO Define actor to use run speed
# This needs to be changed with navigation agent 3d: _on_navigation_agent_3d_velocity_computed
func perform(_actor: Node, _delta: float, _blackboard: Dictionary) -> bool:
	var entity: NPCEntity = _actor
	assert(entity, "FleeFromEnemy: actor is not NPCEntity: " + str(_actor))
	var controller: NPCMovementController = entity.npc_movement_controller
	var enemy_position: Vector3 = _blackboard[GoapKeys.ENEMY_POSITION]
	var actor_position: Vector3 = _blackboard[GoapKeys.POSITION]
	var enemy_nearby: bool = _blackboard[GoapKeys.ENEMY_NEARBY]

	# Recalculate flee direction every frame for dynamic fleeing
	var flee_direction: Vector3 = (actor_position - enemy_position).normalized()
	var flee_distance: float = 15.0
	var flee_target: Vector3 = actor_position + flee_direction * flee_distance

	controller.set_physics_process(true)
	controller.update_target_location(flee_target)

	if not enemy_nearby:
		controller.set_physics_process(false)
		return true

	return false
