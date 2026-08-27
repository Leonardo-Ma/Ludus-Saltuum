## Interface class
## This is attached to goap controller node
## Controls the npc specific blackboard
@abstract class_name GoapMemory
extends Node

const MIN_TICKS_BETWEEN_UPDATES: int = 10
const MAX_TICKS_BETWEEN_UPDATES: int = 20
var _ticks_until_update: int = 0

@warning_ignore("unused_private_class_variable")
var _actor: Node = null
var _blackboard: Dictionary = {}

# To override
@abstract func init(actor: Node) -> void

# To override
## Throttled by update_blackboard()
@abstract func _refresh_blackboard() -> void


## Called every GoapAgent tick. Throttles _refresh_blackboard() to a random interval
func update_blackboard() -> void:
	_ticks_until_update -= 1
	if _ticks_until_update > 0:
		return
	_refresh_blackboard()
	_ticks_until_update = randi_range(MIN_TICKS_BETWEEN_UPDATES, MAX_TICKS_BETWEEN_UPDATES)


## Used for urgent reactions (flee, use potion...)
func force_refresh_blackboard() -> void:
	_ticks_until_update = 0


func get_blackboard() -> Dictionary:
	return _blackboard


func get_actor() -> Node:
	return _actor
