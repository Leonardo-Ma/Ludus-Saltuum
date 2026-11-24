class_name ReachRangedAttackRangeGoal
extends GoapGoal


func is_valid(_blackboard: Dictionary) -> bool:
	return _blackboard[GoapKeys.ENEMY_ALIVE] and _blackboard[GoapKeys.ENEMY_REACHABLE] and not _blackboard[GoapKeys.ENEMY_IN_RANGED_RANGE]


func priority() -> int:
	return 9


func get_desired_state() -> Dictionary:
	return { GoapKeys.ENEMY_IN_RANGED_RANGE: true }
