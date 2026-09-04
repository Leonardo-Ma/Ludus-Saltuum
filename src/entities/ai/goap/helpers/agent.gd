## This integrates the actor (NPC) with GOAP.
class_name GoapAgent
extends Node

const GOAL_SWITCH_DELAY: float = 0.1

var _goals: Array[GoapGoal]
var _current_goal: GoapGoal
var _current_plan: Array[GoapAction]
var _current_plan_step: int = 0

## Memory has actor and blackboard
var _goap_memory: GoapMemory

## Per-entity action planner
var _action_planner: GoapActionPlanner
var _goal_switch_cooldown: float = 0.0
var _sorted_goals_cache: Array[GoapGoal] = [] # Cache for performance


# For ever frame, is current goal still highest priority?
# if not request the action planner a new plan for new highest priority
func _process(delta: float) -> void:
	_goap_memory.update_blackboard()
	_goal_switch_cooldown -= delta

	var blackboard: Dictionary = _goap_memory.get_blackboard()

	var current_valid: bool = _is_current_valid(blackboard)

	var best_goal: GoapGoal = _get_best_goal()

	if best_goal == null:
		if _current_goal != null or not _current_plan.is_empty():
			_clear_current()
		return

	var needs_new_plan: bool = false

	if not current_valid:
		needs_new_plan = true
	elif _current_goal == null or _current_plan.is_empty():
		needs_new_plan = true
	elif _goal_switch_cooldown <= 0.0 and best_goal.priority() > _current_goal.priority():
		# Higher priority goal available
		needs_new_plan = true

	if needs_new_plan:
		_try_get_new_plan(blackboard)

	if not _current_plan.is_empty():
		_follow_plan(delta, blackboard)


func _is_current_valid(blackboard: Dictionary) -> bool:
	# Check current goal
	if _current_goal != null and not _current_goal.is_valid(blackboard):
		return false

	if _current_plan.is_empty():
		return _current_goal == null # Valid if no goal and no plan

	if _current_plan_step < _current_plan.size():
		var current_action: GoapAction = _current_plan[_current_plan_step]
		if not current_action.is_valid(blackboard):
			return false

	return true


func _try_get_new_plan(blackboard: Dictionary) -> void:
	# Try goals in priority order
	var goals_to_try: Array[GoapGoal] = _get_sorted_goals()

	for potential_goal: GoapGoal in goals_to_try:
		if not potential_goal.is_valid(blackboard):
			continue

		# Don't downgrade goals while current plan is still valid
		if _current_goal != null and not _current_plan.is_empty():
			if potential_goal.priority() <= _current_goal.priority():
				continue

		var new_plan: Array[GoapAction] = _action_planner.get_plan(potential_goal, blackboard)

		if not new_plan.is_empty():
			_current_goal = potential_goal
			_current_plan = new_plan
			_current_plan_step = 0
			_goal_switch_cooldown = GOAL_SWITCH_DELAY
			return

	if _current_goal == null or not _current_goal.is_valid(blackboard):
		_clear_current()


## Get cached sorted goals (sorted by priority descending)
func _get_sorted_goals() -> Array[GoapGoal]:
	if _sorted_goals_cache.is_empty():
		_sorted_goals_cache = _goals.duplicate()
		_sorted_goals_cache.sort_custom(
			func(a: GoapGoal, b: GoapGoal) -> bool:
				return a.priority() > b.priority(),
		)
	return _sorted_goals_cache


func _clear_current() -> void:
	_current_goal = null
	_current_plan = []
	_current_plan_step = 0


func init(actor: Node, goals: Array[GoapGoal], goap_memory: GoapMemory, actions: Array[GoapAction]) -> void:
	assert(not actions.is_empty(), "GoapAgent: No actions provided for agent: " + actor.name)
	assert(not goals.is_empty(), "GoapAgent: No goals provided for agent: " + actor.name)

	_goap_memory = goap_memory
	_goap_memory.init(actor)
	_goals = goals

	_action_planner = GoapActionPlanner.new()
	_action_planner.set_actions(actions)


func _get_best_goal() -> GoapGoal:
	var highest_priority: GoapGoal = null
	var highest_value: float = -INF
	var blackboard: Dictionary = _goap_memory.get_blackboard()

	for goal: GoapGoal in _goals:
		if goal.is_valid(blackboard):
			var priority: float = goal.priority()
			if priority > highest_value:
				highest_priority = goal
				highest_value = priority

	return highest_priority


func _follow_plan(delta: float, blackboard: Dictionary) -> void:
	if _current_plan_step >= _current_plan.size():
		_clear_current()
		return

	var current_action: GoapAction = _current_plan[_current_plan_step]

	if not current_action.is_valid(blackboard):
		_clear_current()
		return

	var is_step_complete: bool = current_action.perform(_goap_memory.get_actor(), delta, blackboard)

	if is_step_complete:
		if _current_plan_step < _current_plan.size() - 1:
			_current_plan_step += 1
		else:
			_clear_current()
