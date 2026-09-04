class_name Wander
extends GoapGoal


func get_custom_class_name() -> String:
	return "Wander"


func is_valid(_blackboard: Dictionary) -> bool:
	var enemy_nearby: bool = _blackboard.get("enemy_nearby", false)
	var in_combat: bool = _blackboard.get("in_combat", false)
	return not enemy_nearby and not in_combat


func priority() -> int:
	return -1


func get_desired_state() -> Dictionary:
	return { "is_wandering": true }
