class_name ApproachEnemy
extends GoapAction


func get_custom_class_name() -> String:
	return "ApproachEnemy"


func is_valid(_blackboard: Dictionary) -> bool:
	return _blackboard.get("enemy_alive", false) == true


func get_cost(_blackboard: Dictionary) -> int:
	var actor_pos: Vector3 = _blackboard.get("position", Vector3.ZERO)
	var enemy_pos: Vector3 = _blackboard.get("enemy_position", Vector3.ZERO)
	return int(actor_pos.distance_to(enemy_pos))


func get_preconditions() -> Dictionary:
	return { "enemy_in_ranged_range": false }


func get_effects() -> Dictionary:
	return { "enemy_in_ranged_range": true }


func perform(_actor: Node, _delta: float, _blackboard: Dictionary) -> bool:
	if _blackboard.get("enemy_in_ranged_range", false) or _actor.npc_movement_controller.is_navigation_finished():
		_actor.npc_movement_controller.stop()
		return true

	_actor.npc_movement_controller.set_physics_process(true)
	_actor.npc_movement_controller.update_target_location(_blackboard.get("enemy_position", Vector3.ZERO))
	return false
