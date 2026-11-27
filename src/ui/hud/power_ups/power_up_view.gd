class_name PowerUpView
extends MarginContainer

## Displays buffs from assigned actor's active status state

var _status: StatusManager

@onready var power_ups_container: GridContainer = %PowerUpsContainer


func _ready() -> void:
	_refresh_statuses()


## Takes an initial snapshot and refreshes when assigned manager changes
func bind_status(status: StatusManager) -> void:
	if is_instance_valid(_status):
		_status.statuses_changed.disconnect(_refresh_statuses)
	_status = status
	if _status != null:
		_status.statuses_changed.connect(_refresh_statuses)
	_refresh_statuses()


func _refresh_statuses() -> void:
	var slot_count: int = power_ups_container.get_child_count()
	var slot_index: int = 0
	if is_instance_valid(_status):
		# Assign slots in status application order
		for active: ActiveStatusEffect in _status.get_active_statuses():
			if slot_index == slot_count:
				break
			if active.status.hud_icon == null:
				continue
			var slot: PowerUpSlot = power_ups_container.get_child(slot_index)
			slot.display_status(active.status.hud_icon, active.remaining_time, active.total_duration, active.is_infinite())
			slot_index += 1

	for index: int in range(slot_index, slot_count):
		var slot: PowerUpSlot = power_ups_container.get_child(index)
		slot.clear()
