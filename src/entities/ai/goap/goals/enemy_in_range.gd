class_name EnemyInRange
extends GoapGoal


func get_custom_class_name() -> String:
	return "EnemyInRange"


func is_valid(_blackboard: Dictionary) -> bool:
	return _blackboard[GoapKeys.ENEMY_NEARBY] == true and _blackboard[GoapKeys.ENEMY_IN_MELEE_RANGE] == false


func priority() -> int:
	return 9


func get_desired_state() -> Dictionary:
	return { GoapKeys.ENEMY_IN_MELEE_RANGE: true }
