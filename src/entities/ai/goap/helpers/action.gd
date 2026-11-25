@abstract class_name GoapAction
extends Node


@abstract func get_custom_class_name() -> String


## Should action be considered?
func is_valid(_blackboard: Dictionary) -> bool:
	return true


## Action Cost. This is a function so it handles situational costs, when the world
## state is considered when calculating the cost.
## Costs must be non-negative for uniform-cost search
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


## Checks action eligibility before planning or starting execution
func can_start(blackboard: Dictionary) -> bool:
	return matches_state(blackboard, get_preconditions()) and is_valid(blackboard)


## Checks whether state contains every required key and value
static func matches_state(state: Dictionary, required_state: Dictionary) -> bool:
	for key: String in required_state:
		if not state.has(key) or state[key] != required_state[key]:
			return false
	return true


## Release action-owned state on completion or interruption
func exit(_actor: Node) -> void:
	pass


## Action implementation called on every loop.
## "actor" is the NPC using the AI
## "delta" is the time in seconds since last loop.
## Returns true when the task is complete.
func perform(_actor: Node, _delta: float, _blackboard: Dictionary) -> bool:
	return false
