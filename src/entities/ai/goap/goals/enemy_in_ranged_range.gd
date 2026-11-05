class_name EnemyInRangedRange
extends GoapGoal


func get_custom_class_name() -> String:
	return "EnemyInRangedRange"


func is_valid(_blackboard: Dictionary) -> bool:
	return _blackboard.get("enemy_alive", false) == true and _blackboard.get("enemy_in_ranged_range", false) == false


func priority() -> int:
	return 9


func get_desired_state() -> Dictionary:
	return { "enemy_in_ranged_range": true }
