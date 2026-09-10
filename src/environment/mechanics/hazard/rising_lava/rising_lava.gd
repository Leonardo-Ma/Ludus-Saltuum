class_name RisingLava
extends Hazard

@export_range(0.1, 10.0, 0.1, "suffix:m/s") var rise_speed: float = 1.0
## If true, snaps back to just below the newly activated checkpoint on respawn
@export var resets_on_checkpoint: bool = false


func _child_ready() -> void:
	assert(attack and attack.hitkill, "RisingLava: attack must be hitkill in " + name)
	if resets_on_checkpoint:
		CheckpointManager.checkpoint_activated.connect(_on_checkpoint_activated)


func _physics_process(delta: float) -> void:
	global_position.y += rise_speed * delta


func _on_checkpoint_activated(checkpoint_position: Vector3) -> void:
	global_position.y = checkpoint_position.y - 1.0
