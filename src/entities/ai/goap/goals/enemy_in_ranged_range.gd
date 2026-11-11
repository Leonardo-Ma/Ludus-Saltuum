class_name EnemyInRangedRange
extends GoapGoal


func get_custom_class_name() -> String:
	return "EnemyInRangedRange"


func is_valid(_blackboard: Dictionary) -> bool:
	return _blackboard[GoapKeys.ENEMY_ALIVE] == true and _blackboard[GoapKeys.ENEMY_IN_RANGED_RANGE] == false


func priority() -> int:
	return 9


func get_desired_state() -> Dictionary:
	return { GoapKeys.ENEMY_IN_RANGED_RANGE: true }
