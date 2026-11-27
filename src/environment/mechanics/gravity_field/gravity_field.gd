extends TriggerArea3D

## Overrides player gravity while inside

@export_range(0.0, 50.0, 0.1, "suffix:m/s²") var gravity_override: float = 3.0


func _init() -> void:
	# BUG This is wrong
	assert(get_children().is_empty(), "Collision shape must be added as child of instance, not original parent scene")


func _child_ready() -> void:
	pass


var _previous_gravity_multipliers: Dictionary[PlayerMovementComponent, float] = { }


func _on_trigger_entered(body: Node3D) -> void:
	if body.is_in_group(Groups.PLAYERS):
		var movement: PlayerMovementComponent = body.get_node(^"%PlayerMovementComponent")
		assert(movement, "PlayerMovementComponent missing in " + name)
		_previous_gravity_multipliers[movement] = movement.gravity_multiplier
		movement.gravity_multiplier = gravity_override / float(ProjectSettings.get_setting("physics/3d/default_gravity"))


func _on_trigger_exited(body: Node3D) -> void:
	if body.is_in_group(Groups.PLAYERS):
		var movement: PlayerMovementComponent = body.get_node(^"%PlayerMovementComponent")
		assert(movement, "PlayerMovementComponent missing in " + name)
		if _previous_gravity_multipliers.has(movement):
			movement.gravity_multiplier = _previous_gravity_multipliers[movement]
			_previous_gravity_multipliers.erase(movement)
