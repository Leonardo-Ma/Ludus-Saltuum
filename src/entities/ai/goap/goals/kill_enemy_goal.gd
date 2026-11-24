class_name KillEnemyGoal
extends GoapGoal


# Not valid if not in combat
func is_valid(_blackboard: Dictionary) -> bool:
	return _blackboard[GoapKeys.IN_COMBAT] == true


func priority() -> int:
	return 10


func get_desired_state() -> Dictionary:
	return { GoapKeys.ENEMY_ALIVE: false }
