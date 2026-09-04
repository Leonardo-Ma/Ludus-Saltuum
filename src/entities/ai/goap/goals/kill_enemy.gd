class_name KillEnemy
extends GoapGoal


func get_custom_class_name() -> String:
	return "KillEnemy"


# Not valid if not in combat
func is_valid(_blackboard: Dictionary) -> bool:
	return _blackboard.get("in_combat", false) == true


func priority() -> int:
	return 10


func get_desired_state() -> Dictionary:
	return { "enemy_alive": false }
