# TODO Refactor to ChaseEnemy
class_name GotoEnemy
extends GoapAction


func get_custom_class_name() -> String:
	return "GotoEnemy"


func is_valid(_blackboard: Dictionary) -> bool:
	return _blackboard.get("enemy_alive", false) == true


func get_cost(_blackboard: Dictionary) -> int:
	var actor_pos: Vector3 = _blackboard.get("position", Vector3.ZERO)
	var enemy_pos: Vector3 = _blackboard.get("enemy_position", Vector3.ZERO)
	return int(actor_pos.distance_to(enemy_pos))


func get_preconditions() -> Dictionary:
	return { "enemy_in_melee_range": false }


func get_effects() -> Dictionary:
	return { "enemy_in_melee_range": true }


# TODO Define actor to use movement's speed
# This needs to be changed with navigation agent 3d: _on_navigation_agent_3d_velocity_computed
func perform(_actor: Node, _delta: float, _blackboard: Dictionary) -> bool:
	var enemy_position: Vector3 = _blackboard.get("enemy_position", Vector3.ZERO)
	var enemy_in_melee_range: bool = _blackboard.get("enemy_in_melee_range", false)

	_actor.navigation_controller.set_physics_process(true)
	_actor.navigation_controller.update_target_location(enemy_position)

	if enemy_in_melee_range:
		_actor.navigation_controller.set_physics_process(false)
		return true
	return false
