## Overrides player gravity while inside
extends TriggerArea3D

@export_range(0.0, 50.0, 0.1, "suffix:m/s²") var gravity_override: float = 3.0


func _init() -> void:
	# BUG This is wrong
	assert(get_children().is_empty(), "Collision shape must be added as child of instance, not original parent scene")


func _child_ready() -> void:
	pass


func _on_trigger_entered(body: Node3D) -> void:
	if body.is_in_group(Groups.PLAYERS):
		body.movement_controller.gravity = gravity_override


func _on_trigger_exited(body: Node3D) -> void:
	if body.is_in_group(Groups.PLAYERS):
		body.movement_controller.gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
