@icon("uid://b2ggug31fd52y") # star.png
class_name StatusManager
extends Node

signal statuses_changed
signal event_dispatched(event_name: StringName, data: Dictionary)

@export_category("Statuses")
## Statuses that are permanent/innate (like passives or racial bonuses)
@export var permanent_statuses: Array[StatusEffect] = []
## Statuses that are applied temporarily at the start (e.g., starting with a timed buff)
@export var initial_statuses: Array[StatusEffect] = []

var _active_statuses: Dictionary = { } # Dictionary[StringName, ActiveStatusEffect]

var _target: Node = null


func _ready() -> void:
	_target = get_parent()
	for status: StatusEffect in permanent_statuses:
		assert(status.resource_path.get_extension() == ".tres", "status " + name + " must be external .tres attached, not edited in editor inspector")
		if status:
			apply_status(status)
	for status: StatusEffect in initial_statuses:
		assert(status.resource_path.get_extension() == ".tres", "status " + name + " must be external .tres attached, not edited in editor inspector")
		if status:
			apply_status(status)


func _process(delta: float) -> void:
	for key: StringName in _active_statuses:
		var active: ActiveStatusEffect = _active_statuses[key]
		active.process_time(delta)


func apply_status(status: StatusEffect) -> void:
	if _active_statuses.has(status.get_id()):
		_active_statuses[status.get_id()].handle_reapplication()
	else:
		var new_active: ActiveStatusEffect = ActiveStatusEffect.new(status, _target)
		new_active.expired.connect(_on_status_expired)
		_active_statuses[status.get_id()] = new_active

	statuses_changed.emit()


func remove_status(status_id: StringName) -> void:
	if _active_statuses.has(status_id):
		var active: ActiveStatusEffect = _active_statuses[status_id]
		active.expired.disconnect(_on_status_expired)
		active.remove()
		_active_statuses.erase(status_id)
		statuses_changed.emit()


func _on_status_expired(active_status: ActiveStatusEffect) -> void:
	remove_status(active_status.status.get_id())


func dispatch_event(event_name: StringName, data: Dictionary) -> void:
	for key: StringName in _active_statuses:
		var active: ActiveStatusEffect = _active_statuses[key]
		active.status.on_event(_target, event_name, data)
	event_dispatched.emit(event_name, data)


func clear_temporary_statuses() -> void:
	var keys_to_remove: Array[StringName] = []
	for key: StringName in _active_statuses:
		var active: ActiveStatusEffect = _active_statuses[key]
		if active.status not in permanent_statuses:
			keys_to_remove.append(key)

	for key: StringName in keys_to_remove:
		remove_status(key)
