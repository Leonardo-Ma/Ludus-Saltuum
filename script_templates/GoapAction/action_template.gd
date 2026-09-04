class_name ActionName
extends GoapAction


func get_custom_class_name() -> String:
	return "ActionName"


func is_valid(_blackboard: Dictionary) -> bool:
	return true


func get_cost(_blackboard: Dictionary) -> int:
	return 0


func get_preconditions() -> Dictionary:
	return { "precondition": true }


func get_effects() -> Dictionary:
	return { "post_effect": true }


func perform(_actor: Node, _delta: float, _blackboard: Dictionary) -> bool:
	return false
