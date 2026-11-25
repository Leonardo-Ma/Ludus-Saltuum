extends ProjectTest

## Verifies GoapActionPlanner finds valid, optimal plans and terminates safely


class CheapAction:
	extends GoapAction

	var available: bool = true
	var perform_count: int = 0
	var exit_count: int = 0


	func get_custom_class_name() -> String:
		return "CheapAction"


	func is_valid(_blackboard: Dictionary) -> bool:
		return available


	func get_cost(_blackboard: Dictionary) -> int:
		return 1


	func get_preconditions() -> Dictionary:
		return { }


	func get_effects() -> Dictionary:
		return { "door_open": true }


	func perform(_actor: Node, _delta: float, _blackboard: Dictionary) -> bool:
		perform_count += 1
		return false


	func exit(_actor: Node) -> void:
		exit_count += 1


class BackupAction:
	extends CheapAction

	func get_custom_class_name() -> String:
		return "BackupAction"


	func get_cost(_blackboard: Dictionary) -> int:
		return 10


class ExpensiveAction:
	extends GoapAction

	func get_custom_class_name() -> String:
		return "ExpensiveAction"


	func get_cost(_blackboard: Dictionary) -> int:
		return 10


	func get_preconditions() -> Dictionary:
		return { "has_key": true }


	func get_effects() -> Dictionary:
		return { "door_open": true }


class GetKeyAction:
	extends GoapAction

	func get_custom_class_name() -> String:
		return "GetKeyAction"


	func get_cost(_blackboard: Dictionary) -> int:
		return 1


	func get_preconditions() -> Dictionary:
		return { }


	func get_effects() -> Dictionary:
		return { "has_key": true }


class OpenDoorGoal:
	extends GoapGoal

	func get_custom_class_name() -> String:
		return "OpenDoorGoal"


	func get_desired_state() -> Dictionary:
		return { "door_open": true }


class ConsumeKeyAction:
	extends ExpensiveAction

	func get_custom_class_name() -> String:
		return "ConsumeKeyAction"


	func get_effects() -> Dictionary:
		return { "door_open": true, "has_key": false }


class RecoverKeyAction:
	extends GetKeyAction

	func get_custom_class_name() -> String:
		return "RecoverKeyAction"


	func is_valid(blackboard: Dictionary) -> bool:
		return blackboard["door_open"] == true


class KeepKeyGoal:
	extends OpenDoorGoal

	func get_desired_state() -> Dictionary:
		return { "door_open": true, "has_key": true }


class DoorMemory:
	extends GoapMemory

	func init(actor: Node) -> void:
		_actor = actor
		_blackboard = { "door_open": false }


	func _refresh_blackboard() -> void:
		pass


class RouteAction:
	extends GoapAction

	var _from_step: int
	var _to_step: int
	var _cost: int


	func _init(from_step: int, to_step: int, cost: int) -> void:
		_from_step = from_step
		_to_step = to_step
		_cost = cost


	func get_custom_class_name() -> String:
		return "RouteAction"


	func get_cost(_blackboard: Dictionary) -> int:
		return _cost


	func get_preconditions() -> Dictionary:
		return { "route_step": _from_step }


	func get_effects() -> Dictionary:
		return { "route_step": _to_step, "door_open": _to_step > GoapActionPlanner.MAX_DEPTH }


func run_tests() -> void:
	_test_finds_cheapest_plan()
	_test_no_plan_when_unreachable()
	_test_action_order_independence()
	_test_conflicting_effects()
	_test_depth_limit_preserves_shorter_route()
	_test_replans_when_action_becomes_invalid()
	print("GOAP planner test completed.")


func _test_finds_cheapest_plan() -> void:
	var planner: GoapActionPlanner = GoapActionPlanner.new()
	var cheap: CheapAction = CheapAction.new()
	var expensive: ExpensiveAction = ExpensiveAction.new()
	var get_key: GetKeyAction = GetKeyAction.new()
	var goal: OpenDoorGoal = OpenDoorGoal.new()
	planner.set_actions([cheap, expensive, get_key])

	var plan: Array[GoapAction] = planner.get_plan(goal, { })

	assert(not plan.is_empty(), "Expected a plan in " + name)
	assert(
		plan.size() == 1 and plan[0] == cheap,
		(
			"Expected cheapest single-action plan in " + name
			+ ", got %s"
			% str(
				plan.map(
					func(a: GoapAction) -> String:
						return a.get_custom_class_name(),
				)
			)
		),
	)
	goal.free()
	cheap.free()
	expensive.free()
	get_key.free()
	planner.free()


func _test_no_plan_when_unreachable() -> void:
	var planner: GoapActionPlanner = GoapActionPlanner.new()
	var expensive: ExpensiveAction = ExpensiveAction.new()
	var goal: OpenDoorGoal = OpenDoorGoal.new()
	planner.set_actions([expensive])

	var plan: Array[GoapAction] = planner.get_plan(goal, { })

	assert(plan.is_empty(), "Expected no plan when 'has_key' is unreachable in " + name)
	goal.free()
	expensive.free()
	planner.free()


func _test_action_order_independence() -> void:
	var planner: GoapActionPlanner = GoapActionPlanner.new()
	var cheap: CheapAction = CheapAction.new()
	var backup: BackupAction = BackupAction.new()
	var goal: OpenDoorGoal = OpenDoorGoal.new()
	cheap.available = false

	planner.set_actions([cheap, backup])
	assert(planner.get_plan(goal, { }) == [backup], "Expected valid plan with cheapest action first in " + name)
	planner.set_actions([backup, cheap])
	assert(planner.get_plan(goal, { }) == [backup], "Expected valid plan with cheapest action last in " + name)

	goal.free()
	cheap.free()
	backup.free()
	planner.free()


func _test_conflicting_effects() -> void:
	var planner: GoapActionPlanner = GoapActionPlanner.new()
	var consume_key: ConsumeKeyAction = ConsumeKeyAction.new()
	var recover_key: RecoverKeyAction = RecoverKeyAction.new()
	var goal: KeepKeyGoal = KeepKeyGoal.new()
	var blackboard: Dictionary = { "has_key": true, "door_open": false }
	planner.set_actions([recover_key, consume_key])

	assert(planner.get_plan(goal, blackboard) == [consume_key, recover_key], "Expected plan to restore key after opening door in " + name)
	assert(blackboard == { "has_key": true, "door_open": false }, "Planning must preserve live blackboard in " + name)

	goal.free()
	consume_key.free()
	recover_key.free()
	planner.free()


func _test_depth_limit_preserves_shorter_route() -> void:
	var planner: GoapActionPlanner = GoapActionPlanner.new()
	var goal: OpenDoorGoal = OpenDoorGoal.new()
	var max_depth: int = GoapActionPlanner.MAX_DEPTH
	var finish: RouteAction = RouteAction.new(max_depth, max_depth + 1, 0)
	var shortcut: RouteAction = RouteAction.new(0, max_depth, 10)
	var actions: Array[GoapAction] = [finish]
	for step: int in range(max_depth):
		actions.append(RouteAction.new(step, step + 1, 0))
	var blackboard: Dictionary = { "route_step": 0, "door_open": false }
	planner.set_actions(actions)
	assert(planner.get_plan(goal, blackboard).is_empty(), "Expected route beyond step limit to fail in " + name)
	var reachable_state: Dictionary = { "route_step": 1, "door_open": false }
	assert(planner.get_plan(goal, reachable_state).size() == max_depth, "Expected route at step limit to succeed in " + name)

	actions.append(shortcut)
	planner.set_actions(actions)
	assert(planner.get_plan(goal, blackboard) == [shortcut, finish], "Expected shorter route within step limit in " + name)

	goal.free()
	for action: GoapAction in actions:
		action.free()
	planner.free()


func _test_replans_when_action_becomes_invalid() -> void:
	var agent: GoapAgent = GoapAgent.new()
	var memory: DoorMemory = DoorMemory.new()
	var cheap: CheapAction = CheapAction.new()
	var backup: BackupAction = BackupAction.new()
	var goal: OpenDoorGoal = OpenDoorGoal.new()
	agent.add_child(memory)
	agent.init(self, [goal], memory, [cheap, backup])
	agent._process(0.0)
	assert(cheap.perform_count == 1 and backup.perform_count == 0, "Expected cheapest action to start in " + name)

	cheap.available = false
	memory.force_refresh_blackboard()
	agent._process(0.0)
	assert(cheap.perform_count == 1 and cheap.exit_count == 1, "Expected invalid action to exit once in " + name)
	assert(backup.perform_count == 1, "Expected immediate replacement for same goal in " + name)

	agent.free()
