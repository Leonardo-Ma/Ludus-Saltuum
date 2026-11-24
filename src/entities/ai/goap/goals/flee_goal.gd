class_name FleeGoal
extends GoapGoal


func is_valid(_blackboard: Dictionary) -> bool:
	return _blackboard[GoapKeys.LOW_HEALTH] == true and _blackboard[GoapKeys.ENEMY_NEARBY] == true


func priority() -> int:
	return 100


func get_desired_state() -> Dictionary:
	return { GoapKeys.ENEMY_NEARBY: false }
