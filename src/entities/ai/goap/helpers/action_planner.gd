# TODO Review, improve, learn
class_name GoapActionPlanner
extends Node

## Finds lowest-cost plans by exploring simulated blackboard states

const MAX_DEPTH: int = 15


class SearchStep:
	extends RefCounted

	var state: Dictionary
	var cost: int
	var depth: int
	var action: GoapAction
	var previous: SearchStep


	func _init(snapshot: Dictionary, total_cost: int, step_depth: int, step_action: GoapAction, parent_step: SearchStep) -> void:
		state = snapshot
		cost = total_cost
		depth = step_depth
		action = step_action
		previous = parent_step


var _actions: Array[GoapAction]


## Set actions available for planning.
## This can be changed in runtime for more dynamic options.
func set_actions(actions: Array[GoapAction]) -> void:
	_actions = actions
	assert(not _actions.is_empty(), "GoapActionPlanner: No actions provided in " + name)


## Returns actions in execution order for goal and initial blackboard
func get_plan(goal: GoapGoal, blackboard: Dictionary) -> Array[GoapAction]:
	assert(goal, "GoapActionPlanner: goal is null in " + name)

	var desired_state: Dictionary = goal.get_desired_state()
	assert(not desired_state.is_empty(), "GoapActionPlanner: Goal '%s' has no desired state in %s" % [goal.get_custom_class_name(), name])
	assert(not _actions.is_empty(), "GoapActionPlanner: Cannot plan with no actions available in " + name)
	if GoapAction.matches_state(blackboard, desired_state):
		return [] # Goal already achieved

	var initial_state: Dictionary = blackboard.duplicate()
	# Dictionary hashes depend on insertion order
	initial_state.sort()
	var root: SearchStep = SearchStep.new(initial_state, 0, 0, null, null)
	var frontier: Array[SearchStep] = [root]
	var best_costs: Dictionary[Dictionary, Dictionary] = { initial_state: { 0: 0 } }

	while not frontier.is_empty():
		var step: SearchStep = frontier.pop_back()
		var costs_by_depth: Dictionary = best_costs[step.state]
		if costs_by_depth.get(step.depth) != step.cost:
			continue

		# First complete plan reached has lowest cost
		if GoapAction.matches_state(step.state, desired_state):
			return _build_plan(step)
		if step.depth >= MAX_DEPTH:
			continue

		# Expand actions whose validity and preconditions match simulated blackboard
		for action: GoapAction in _actions:
			if not action.can_start(step.state):
				continue

			# Apply effects to a simulated blackboard
			var next_state: Dictionary = step.state.duplicate()
			next_state.merge(action.get_effects(), true)
			next_state.sort()

			var action_cost: int = action.get_cost(step.state)
			assert(action_cost >= 0, "GoapActionPlanner: Negative cost for '%s' in %s" % [action.get_custom_class_name(), name])
			var next_step: SearchStep = SearchStep.new(next_state, step.cost + action_cost, step.depth + 1, action, step)
			if _record_best_cost(best_costs, next_step):
				var index: int = frontier.bsearch_custom(next_step, _has_higher_cost)
				frontier.insert(index, next_step)

	return []


func _record_best_cost(best_costs: Dictionary[Dictionary, Dictionary], step: SearchStep) -> bool:
	var costs_by_depth: Dictionary = best_costs.get_or_add(step.state, { })
	# Prune cycles and costlier paths that leave no more steps to reach goal
	for depth: int in costs_by_depth:
		if depth <= step.depth and costs_by_depth[depth] <= step.cost:
			return false
	for depth: int in costs_by_depth.keys():
		if depth >= step.depth and costs_by_depth[depth] >= step.cost:
			costs_by_depth.erase(depth)
	costs_by_depth[step.depth] = step.cost
	return true


func _has_higher_cost(first: SearchStep, second: SearchStep) -> bool:
	return first.cost > second.cost


func _build_plan(goal_step: SearchStep) -> Array[GoapAction]:
	var plan: Array[GoapAction] = []
	var step: SearchStep = goal_step
	# Prepend actions while tracing back from goal to initial state
	while step.previous != null:
		plan.push_front(step.action)
		step = step.previous
	return plan


## Prints plan. Used for debugging only.
func _print_plan(plan: Dictionary) -> void:
	var action_names: Array[String] = []
	for action: GoapAction in plan["actions"]:
		action_names.append(action.get_custom_class_name())
	var info: Dictionary = { "cost": plan["cost"], "actions": action_names }
	print(info)
