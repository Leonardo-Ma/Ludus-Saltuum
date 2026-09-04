class_name Flee
extends GoapGoal


func get_custom_class_name() -> String:
	return "Flee"


func is_valid(_blackboard: Dictionary) -> bool:
	# Only valid when health is low and enemy is nearby
	var low_health: bool = _blackboard.get("low_health", false)
	var enemy_nearby: bool = _blackboard.get("enemy_nearby", false)
	return low_health and enemy_nearby


func priority() -> int:
	return 100


func get_desired_state() -> Dictionary:
	return { "enemy_nearby": false }
