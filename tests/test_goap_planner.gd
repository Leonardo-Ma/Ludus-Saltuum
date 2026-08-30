## Verifies GoapActionPlanner finds valid, optimal plans and terminates safely
extends Node


class CheapAction:
	extends GoapAction

	func get_custom_class_name() -> String:
		return "CheapAction"

	func get_cost(_blackboard: Dictionary) -> int:
		return 1

	func get_preconditions() -> Dictionary:
		return {}

	func get_effects() -> Dictionary:
		return {"door_open": true}


class ExpensiveAction:
	extends GoapAction

	func get_custom_class_name() -> String:
		return "ExpensiveAction"

	func get_cost(_blackboard: Dictionary) -> int:
		return 10

	func get_preconditions() -> Dictionary:
		return {"has_key": true}

	func get_effects() -> Dictionary:
		return {"door_open": true}


class GetKeyAction:
	extends GoapAction

	func get_custom_class_name() -> String:
		return "GetKeyAction"

	func get_cost(_blackboard: Dictionary) -> int:
		return 1

	func get_preconditions() -> Dictionary:
		return {}

	func get_effects() -> Dictionary:
		return {"has_key": true}


class OpenDoorGoal:
	extends GoapGoal

	func get_custom_class_name() -> String:
		return "OpenDoorGoal"

	func get_desired_state() -> Dictionary:
		return {"door_open": true}


func _ready() -> void:
	if not OS.is_debug_build():
		queue_free()
		return

	_test_finds_cheapest_plan()
	_test_no_plan_when_unreachable()
	print("GOAP planner test completed.")
	self.queue_free()


func _test_finds_cheapest_plan() -> void:
	var planner: GoapActionPlanner = GoapActionPlanner.new()
	var cheap: CheapAction = CheapAction.new()
	var expensive: ExpensiveAction = ExpensiveAction.new()
	var get_key: GetKeyAction = GetKeyAction.new()
	planner.set_actions([cheap, expensive, get_key])

	var plan: Array[GoapAction] = planner.get_plan(OpenDoorGoal.new(), {})

	assert(not plan.is_empty(), "GoapActionPlanner: expected a plan, got none")
	assert(
		plan.size() == 1 and plan[0] == cheap,
		(
			"GoapActionPlanner: expected cheapest single-action plan, got %s"
			% str(plan.map(func(a: GoapAction) -> String: return a.get_custom_class_name()))
		),
	)


func _test_no_plan_when_unreachable() -> void:
	var planner: GoapActionPlanner = GoapActionPlanner.new()
	planner.set_actions([ExpensiveAction.new()])

	var plan: Array[GoapAction] = planner.get_plan(OpenDoorGoal.new(), {})

	assert(plan.is_empty(), "GoapActionPlanner: expected no plan when precondition 'has_key' is unreachable, got a plan")
