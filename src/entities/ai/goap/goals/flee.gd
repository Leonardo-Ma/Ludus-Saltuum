class_name Flee
extends GoapGoal


func get_custom_class_name() -> String:
	return "Flee"


func is_valid(_blackboard: Dictionary) -> bool:
	var low_health: bool = _blackboard[GoapKeys.LOW_HEALTH]
	var enemy_reachable: bool = _blackboard[GoapKeys.ENEMY_REACHABLE]
	var enemy_nearby: bool = _blackboard[GoapKeys.ENEMY_NEARBY]

	return (low_health or not enemy_reachable) and enemy_nearby


func priority() -> int:
	return 100


func get_desired_state() -> Dictionary:
	return { GoapKeys.ENEMY_NEARBY: false }
