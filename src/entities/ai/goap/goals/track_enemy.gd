# TODO Refactor to EnemyInRange
class_name TrackEnemy
extends GoapGoal


func get_custom_class_name() -> String:
	return "TrackEnemy"


func is_valid(_blackboard: Dictionary) -> bool:
	return _blackboard.get("enemy_nearby", false) == true and _blackboard.get("enemy_in_melee_range", false) == false


func priority() -> int:
	return 9


func get_desired_state() -> Dictionary:
	return { "enemy_in_melee_range": true }
