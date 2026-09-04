# TODO Review, improve, learn
class_name GoapActionPlanner
extends Node

const MAX_DEPTH: int = 15
const INF_COST: int = 1 << 30

var _actions: Array[GoapAction] = []
var _best_cost_found: int = INF_COST


## Set actions available for planning.
## This can be changed in runtime for more dynamic options.
func set_actions(actions: Array[GoapAction]) -> void:
	_actions = actions
	assert(not _actions.is_empty(), "GoapActionPlanner: No actions provided!")


## Receives a Goal and an optional blackboard.
## Returns a list of actions to be executed.
func get_plan(goal: GoapGoal, blackboard: Dictionary) -> Array[GoapAction]:
	var desired_state: Dictionary = goal.get_desired_state().duplicate()
	if desired_state.is_empty():
		assert(false, "GoapActionPlanner: Goal '%s' has no desired state!" % goal.get_custom_class_name())
		return []

	if _actions.is_empty():
		assert(false, "GoapActionPlanner: Cannot plan with no actions available!")
		return []

	for key: String in desired_state.keys():
		if blackboard.get(key) != null and blackboard.get(key) == desired_state[key]:
			desired_state.erase(key)

	if desired_state.is_empty():
		return [] # Goal already achieved

	var all_plans: Array[Dictionary] = []
	var initial_plan: Array[GoapAction] = []
	_best_cost_found = INF_COST
	_build_plans(desired_state, blackboard.duplicate(), initial_plan, all_plans, 0, 0)

	if all_plans.is_empty():
		return []

	var valid_plans: Array[Dictionary] = []
	var goal_state_full: Dictionary = goal.get_desired_state()
	for plan: Dictionary in all_plans:
		if _verify_plan(plan["actions"], blackboard, goal_state_full):
			valid_plans.append(plan)

	if valid_plans.is_empty():
		return []

	return _get_cheapest_plan(valid_plans)["actions"]


func _verify_plan(plan: Array[GoapAction], initial_blackboard: Dictionary, goal_state: Dictionary) -> bool:
	var state: Dictionary = initial_blackboard.duplicate()
	for action: GoapAction in plan:
		if not action.is_valid(state):
			return false
		var preconditions: Dictionary = action.get_preconditions()
		for key: String in preconditions:
			if not state.has(key) or state.get(key) != preconditions[key]:
				return false
		var effects: Dictionary = action.get_effects()
		for key: String in effects:
			state[key] = effects[key]

	for key: String in goal_state:
		if not state.has(key) or state.get(key) != goal_state[key]:
			return false
	return true


func _build_plans(
	remaining_state: Dictionary,
	blackboard: Dictionary,
	current_plan: Array[GoapAction],
	all_plans: Array[Dictionary],
	depth: int,
	current_cost: int,
) -> void:
	if depth >= MAX_DEPTH:
		return

	# Find actions that satisfy any remaining conditions
	for action: GoapAction in _actions:
		var effects: Dictionary = action.get_effects()
		var new_remaining: Dictionary = remaining_state.duplicate()
		var satisfied_something: bool = false

		# Check if action satisfies any remaining conditions
		for key: String in remaining_state.keys():
			if effects.has(key) and remaining_state[key] == effects[key]:
				new_remaining.erase(key)
				satisfied_something = true

		if not satisfied_something:
			continue

		# Add preconditions to remaining state
		var has_conflict: bool = false
		var preconditions: Dictionary = action.get_preconditions()
		for key: String in preconditions.keys():
			if not blackboard.has(key) or blackboard.get(key) != preconditions[key]:
				if new_remaining.has(key) and new_remaining[key] != preconditions[key]:
					has_conflict = true
					break
				new_remaining[key] = preconditions[key]

		if has_conflict:
			continue

		var action_cost: int = action.get_cost(blackboard)
		var new_cost: int = current_cost + action_cost

		if new_cost > _best_cost_found:
			continue

		# Apply effects to a simulated blackboard
		var new_blackboard: Dictionary = blackboard.duplicate()
		for key: String in effects.keys():
			new_blackboard[key] = effects[key]

		var new_plan: Array[GoapAction] = current_plan.duplicate()
		# Insert at front because we are planning backwards from the goal
		new_plan.push_front(action)

		if _has_cycle(new_plan):
			continue

		if new_remaining.is_empty():
			# Found a complete plan
			if new_cost < _best_cost_found:
				_best_cost_found = new_cost

			(all_plans.append({ "actions": new_plan, "cost": new_cost }))
		else:
			_build_plans(new_remaining, new_blackboard, new_plan, all_plans, depth + 1, new_cost)


func _has_cycle(plan: Array[GoapAction]) -> bool:
	if plan.size() > MAX_DEPTH:
		return true

	# Simple rolling window limit
	var counts: Dictionary = { }
	for action: GoapAction in plan:
		var cls: String = action.get_custom_class_name()
		counts[cls] = counts.get(cls, 0) + 1
		if counts[cls] > 2:
			return true

	return false


func _get_cheapest_plan(plans: Array[Dictionary]) -> Dictionary:
	var best_plan: Dictionary = plans[0]
	for plan: Dictionary in plans:
		if plan["cost"] < best_plan["cost"]:
			best_plan = plan
	return best_plan


## Prints plan. Used for debugging only.
func _print_plan(plan: Dictionary) -> void:
	var action_names: Array[String] = []
	for action: GoapAction in plan["actions"]:
		action_names.append(action.get_custom_class_name())
	var info: Dictionary = { "cost": plan["cost"], "actions": action_names }
	print(info)
