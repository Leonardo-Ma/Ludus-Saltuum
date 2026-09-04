@abstract class_name GoapGoal
extends Node


func get_custom_class_name() -> String:
	return ""


## Should goal be considered?
## Sometimes it's easier than changing priority
## e.g: Ignore combat goals when no enemies near
func is_valid(_blackboard: Dictionary) -> bool:
	return true


## Returns goals priority. This priority can be dynamic. Check
func priority() -> int:
	return 1


## Plan's desired state. It doesn't need to match the raw world state.
## e.g: in your world state you may store "hunger" as a number, but inside your
## goap you can deal with it as "is_hungry".
func get_desired_state() -> Dictionary:
	return { }
