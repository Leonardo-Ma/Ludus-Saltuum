@icon("uid://b2ggug31fd52y")  # star.png
@abstract class_name StatusEffect
extends Resource

enum StackMode {
	NONE = 0,  ## Cannot stack, application is ignored if present
	STACK = 1,  ## Adds a new stack (up to max_stacks), keeps duration
	REPLACE = 2,  ## Refreshes duration to maximum
	ADD_DURATION = 3,  ## Extends existing time
}
enum StatusType {
	BUFF = 0,
	DEBUFF = 1,
	NEUTRAL = 2,
}

@export var type: StatusType = StatusType.NEUTRAL
## Optional tags
@export var tags: Array[StringName] = []

@export_group("Behavior")
## Duration in seconds. -1.0 for infinite duration (passives, equipment)
@export var duration: float = -1.0
@export var stack_mode: StackMode = StackMode.REPLACE

@export_group("Stacks")
## Max number of concurrent stacks allowed if StackMode.STACK
@export var max_stacks: int = 1
## Interval in seconds for the on_tick event to trigger if StackMode.STACK
@export var tick_interval: float = 1.0

## To be overridden
@abstract func get_id() -> StringName

## To be overridden (UI uses this)
@abstract func get_status_name() -> String


#region Optional functions to be overridden
## Applies only once (a temporary buff or debuff)
func on_apply(_target: Node) -> void:
	pass


## When status runs out
func on_remove(_target: Node) -> void:
	pass


## Applies each interval on loop (damage over time (dot), heal over time(hot))
func on_tick(_target: Node, _delta: float) -> void:
	pass


## Dynamic status application, when a certain actions happens (see dispatch_event of status_manager.gd)
## Used in conditional status (thorns, life steal)
func on_event(_target: Node, _event_name: StringName, _data: Dictionary) -> void:
	pass


func is_infinite() -> bool:
	return duration < 0.0
#endregion
