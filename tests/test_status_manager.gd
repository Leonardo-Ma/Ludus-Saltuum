## Verifies StatusManager stack, replace, and add duration reapplication modes
extends Node


class TestStatus:
	extends StatusEffect

	func get_id() -> StringName:
		return &"test_status"


	func get_status_name() -> String:
		return "Test Status"


func _ready() -> void:
	if not OS.is_debug_build():
		queue_free()
		return

	_test_stack_mode_caps_at_max()
	_test_replace_mode_resets_duration()
	_test_add_duration_mode_extends_time()
	print("StatusManager test completed.")
	self.queue_free()


func _test_stack_mode_caps_at_max() -> void:
	var status: TestStatus = TestStatus.new()
	status.stack_mode = StatusEffect.StackMode.STACK
	status.max_stacks = 2
	status.duration = 5.0

	var target: Node = Node.new()
	var active: ActiveStatusEffect = ActiveStatusEffect.new(status, target)

	active.handle_reapplication()
	assert(active.current_stacks == 2, "ActiveStatusEffect: expected 2 stacks, got %d" % active.current_stacks)

	active.handle_reapplication()
	assert(active.current_stacks == 2, "ActiveStatusEffect: expected stacks capped at max_stacks, got %d" % active.current_stacks)

	target.free()


func _test_replace_mode_resets_duration() -> void:
	var status: TestStatus = TestStatus.new()
	status.stack_mode = StatusEffect.StackMode.REPLACE
	status.duration = 5.0

	var target: Node = Node.new()
	var active: ActiveStatusEffect = ActiveStatusEffect.new(status, target)
	active.remaining_time = 1.0

	active.handle_reapplication()
	assert(active.remaining_time == 5.0, "ActiveStatusEffect: REPLACE should reset to full duration, got %f" % active.remaining_time)

	target.free()


func _test_add_duration_mode_extends_time() -> void:
	var status: TestStatus = TestStatus.new()
	status.stack_mode = StatusEffect.StackMode.ADD_DURATION
	status.duration = 5.0

	var target: Node = Node.new()
	var active: ActiveStatusEffect = ActiveStatusEffect.new(status, target)
	active.remaining_time = 2.0

	active.handle_reapplication()
	assert(active.remaining_time == 7.0, "ActiveStatusEffect: ADD_DURATION should add full duration, got %f" % active.remaining_time)

	target.free()
