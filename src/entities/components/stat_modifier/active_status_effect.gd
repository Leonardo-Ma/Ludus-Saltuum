class_name ActiveStatusEffect
extends RefCounted

signal expired(active_status: ActiveStatusEffect)

var status: StatusEffect
var target: PlayerEntity
var current_stacks: int = 1
var remaining_time: float
var tick_timer: float
var duration: float
var stack_mode: StatusEffect.StackMode
var max_stacks: int
var tick_interval: float


func _init(
	_status: StatusEffect,
	_target: PlayerEntity,
	_duration: float,
	_stack_mode: StatusEffect.StackMode,
	_max_stacks: int,
	_tick_interval: float,
) -> void:
	status = _status
	target = _target
	duration = _duration
	stack_mode = _stack_mode
	max_stacks = _max_stacks
	tick_interval = _tick_interval
	remaining_time = duration
	tick_timer = tick_interval
	status.on_apply(self)


func process_time(delta: float) -> void:
	if tick_interval > 0.0:
		tick_timer -= delta
		if tick_timer <= 0.0:
			status.on_tick(self, tick_interval)
			tick_timer = tick_interval

	if not is_infinite():
		remaining_time -= delta
		if remaining_time <= 0.0:
			expired.emit(self)


func handle_reapplication() -> void:
	match stack_mode:
		StatusEffect.StackMode.STACK:
			if current_stacks < max_stacks:
				current_stacks += 1
		StatusEffect.StackMode.REPLACE:
			remaining_time = duration
		StatusEffect.StackMode.ADD_DURATION:
			if not is_infinite():
				remaining_time += duration
		StatusEffect.StackMode.NONE:
			pass


func remove() -> void:
	status.on_remove(self)


func is_infinite() -> bool:
	return duration < 0.0
