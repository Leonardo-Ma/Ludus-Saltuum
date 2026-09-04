class_name FleeFromEnemy
extends GoapAction


func get_custom_class_name() -> String:
	return "FleeFromEnemy"


func is_valid(_blackboard: Dictionary) -> bool:
	return _blackboard.get("low_health", false) == true


func get_cost(_blackboard: Dictionary) -> int:
	return 1


func get_preconditions() -> Dictionary:
	return { "enemy_nearby": true, "low_health": true }


func get_effects() -> Dictionary:
	return { "enemy_nearby": false }


# TODO Define actor to use run speed
# This needs to be changed with navigation agent 3d: _on_navigation_agent_3d_velocity_computed
func perform(_actor: Node, _delta: float, _blackboard: Dictionary) -> bool:
	var enemy_position: Vector3 = _blackboard.get("enemy_position", Vector3.ZERO)
	var actor_position: Vector3 = _blackboard.get("position", _actor.global_position)
	var enemy_nearby: bool = _blackboard.get("enemy_nearby", false)

	# Recalculate flee direction every frame for dynamic fleeing
	var flee_direction: Vector3 = (actor_position - enemy_position).normalized()
	var flee_distance: float = 15.0
	var flee_target: Vector3 = actor_position + flee_direction * flee_distance

	_actor.navigation_controller.set_physics_process(true)
	_actor.navigation_controller.update_target_location(flee_target)

	if not enemy_nearby:
		_actor.navigation_controller.set_physics_process(false)
		return true

	return false
