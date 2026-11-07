class_name LaunchPad
extends Area3D

## Sets player velocity along local +Z on entry, locks input for control_lock_duration so movement_logic does not overwrite it

@export_range(1.0, 100.0, 0.5, "suffix:m/s") var launch_speed: float = 25.0
@export_range(0.05, 3.0, 0.05, "suffix:s") var control_lock_duration: float = 0.4


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	# TODO Handle enemies as well
	var player: PlayerEntity = body as PlayerEntity
	if player == null:
		return

	player.velocity = global_basis.z.normalized() * launch_speed
	# Needed to avoid being overwritten every frame
	player.player_movement_controller.disable_movement(control_lock_duration)
