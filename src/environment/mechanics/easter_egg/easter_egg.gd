extends TriggerArea3D

@export var easter_egg_name: StringName


func _child_ready() -> void:
	assert(easter_egg_name, "Easter egg name missing in " + name)


func _on_trigger_entered(body: Node3D) -> void:
	if body.is_in_group(Groups.CONTROLLED):
		GameEvents.easter_egg_found.emit(easter_egg_name)
