class_name EasterEgg
extends TriggerArea3D

enum Name {
	UNDEFINED = 0,
	FOURTY_TWO = 1,
}

@export var easter_egg_name: Name = 0 as Name


func _child_ready() -> void:
	assert(easter_egg_name != 0, "Easter egg name not defined in " + owner.name)


func _on_trigger_entered(body: Node3D) -> void:
	if body.is_in_group(Groups.CONTROLLED):
		var player: PlayerEntity = body
		player.easter_egg_controller.found.emit(easter_egg_name)
