class_name ApproachEnemy
extends GoapAction


func get_custom_class_name() -> String:
	return "ApproachEnemy"


func is_valid(_blackboard: Dictionary) -> bool:
	return _blackboard[GoapKeys.ENEMY_ALIVE] == true


func get_cost(_blackboard: Dictionary) -> int:
	var actor_pos: Vector3 = _blackboard[GoapKeys.POSITION]
	var enemy_pos: Vector3 = _blackboard[GoapKeys.ENEMY_POSITION]
	return int(actor_pos.distance_to(enemy_pos))


func get_preconditions() -> Dictionary:
	return { GoapKeys.ENEMY_IN_RANGED_RANGE: false }


func get_effects() -> Dictionary:
	return { GoapKeys.ENEMY_IN_RANGED_RANGE: true }


func perform(_actor: Node, _delta: float, _blackboard: Dictionary) -> bool:
	var entity: NPCEntity = _actor
	assert(entity, "ApproachEnemy: actor is not NPCEntity: " + str(_actor))
	var controller: NPCMovementController = entity.npc_movement_controller
	var enemy_position: Vector3 = _blackboard[GoapKeys.ENEMY_POSITION]

	if _blackboard[GoapKeys.ENEMY_IN_RANGED_RANGE] == true:
		controller.stop()
		return true

	controller.set_physics_process(true)
	if not controller.request_target(_blackboard[GoapKeys.ENEMY_POSITION], true) or controller.is_navigation_finished():
		controller.stop()
		return true

	controller.request_target(enemy_position, true)

	return false
