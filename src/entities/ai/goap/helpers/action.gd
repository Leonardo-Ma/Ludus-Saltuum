@abstract class_name GoapAction
extends Node


@abstract func get_custom_class_name() -> String


## Should action be considered?
func is_valid(_blackboard: Dictionary) -> bool:
	return true


## Action Cost. This is a function so it handles situational costs, when the world
## state is considered when calculating the cost.
func get_cost(_blackboard: Dictionary) -> int:
	return 0


## Action requirements.
## Example:
## {
##   "has_wood": true
## }
func get_preconditions() -> Dictionary:
	return { }


## What conditions this action satisfies
## Example:
## {
##   "has_wood": true
## }
func get_effects() -> Dictionary:
	return { }


## Action implementation called on every loop.
## "actor" is the NPC using the AI
## "delta" is the time in seconds since last loop.
## Returns true when the task is complete.
func perform(_actor: Node, _delta: float, _blackboard: Dictionary) -> bool:
	return false
