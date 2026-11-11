## Interface class
## This is attached to goap controller node
## Controls the npc specific blackboard
@abstract class_name GoapMemory
extends Node

const MIN_SECONDS_BETWEEN_UPDATES: float = 0.17
const MAX_SECONDS_BETWEEN_UPDATES: float = 0.33
var _seconds_until_update: float = 0.0

@warning_ignore("unused_private_class_variable")
var _actor: Node = null
var _blackboard: Dictionary = { }


# To override
@abstract func init(actor: Node) -> void


# To override
## Throttled by update_blackboard()
@abstract func _refresh_blackboard() -> void


## Called every GoapAgent tick [br]
## Throttles _refresh_blackboard() to a random interval, returns true when refreshed
func update_blackboard(delta: float) -> bool:
	assert(not _blackboard.is_empty(), "GoapMemory: init() must populate blackboard in " + name)

	_seconds_until_update -= delta
	if _seconds_until_update > 0.0:
		return false
	_refresh_blackboard()
	_seconds_until_update = randf_range(MIN_SECONDS_BETWEEN_UPDATES, MAX_SECONDS_BETWEEN_UPDATES)
	return true


## Used for urgent reactions (flee, use potion...)
func force_refresh_blackboard() -> void:
	_seconds_until_update = 0.0


func get_blackboard() -> Dictionary:
	return _blackboard


func get_actor() -> Node:
	return _actor
