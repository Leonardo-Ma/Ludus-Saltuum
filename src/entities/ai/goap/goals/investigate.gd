class_name Investigate
extends GoapGoal


func get_custom_class_name() -> String:
	return "Investigate"


func is_valid(_blackboard: Dictionary) -> bool:
	return _blackboard[GoapKeys.HAS_INVESTIGATION_POINT] and not _blackboard[GoapKeys.IN_COMBAT] and not _blackboard[GoapKeys.LOW_HEALTH]


func priority() -> int:
	return 5


func get_desired_state() -> Dictionary:
	return { GoapKeys.IS_INVESTIGATING: true }
