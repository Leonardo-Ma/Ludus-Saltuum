class_name Wander
extends GoapGoal


func get_custom_class_name() -> String:
	return "Wander"


func is_valid(_blackboard: Dictionary) -> bool:
	var enemy_nearby: bool = _blackboard[GoapKeys.ENEMY_NEARBY]
	var enemy_reachable: bool = _blackboard[GoapKeys.ENEMY_REACHABLE]
	var in_combat: bool = _blackboard[GoapKeys.IN_COMBAT]
	return not in_combat and (not enemy_nearby or not enemy_reachable)


func priority() -> int:
	return -1


func get_desired_state() -> Dictionary:
	return { GoapKeys.IS_WANDERING: true }
