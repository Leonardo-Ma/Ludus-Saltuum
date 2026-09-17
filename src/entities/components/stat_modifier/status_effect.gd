@icon("uid://b2ggug31fd52y") # star.png
@abstract class_name StatusEffect
extends Resource

enum StackMode {
	NONE = 0, ## Cannot stack, application is ignored if present
	STACK = 1, ## Adds a new stack (up to max_stacks), keeps duration
	REPLACE = 2, ## Refreshes duration to maximum
	ADD_DURATION = 3, ## Extends existing time
}

enum StatusType {
	BUFF = 0,
	DEBUFF = 1,
	NEUTRAL = 2,
}

@export var type: StatusType = StatusType.NEUTRAL
## Optional tags
@export var tags: Array[StringName] = []


## To be overridden
@abstract func get_id() -> StringName


## To be overridden (UI uses this)
@abstract func get_status_name() -> String

#region Optional functions to be overridden

## Applies only once (a temporary buff or debuff)
func on_apply(_active_status: ActiveStatusEffect) -> void:
	pass


## When status runs out
func on_remove(_active_status: ActiveStatusEffect) -> void:
	pass


## Applies each interval on loop (damage over time (dot), heal over time(hot))
func on_tick(_active_status: ActiveStatusEffect, _delta: float) -> void:
	pass


## Dynamic status application, when a certain actions happens (see dispatch_event of status_manager.gd)
## Used in conditional status (thorns, life steal)
func on_event(_active_status: ActiveStatusEffect, _event_name: StringName, _data: Dictionary) -> void:
	pass

#endregion
