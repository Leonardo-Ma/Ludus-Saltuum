class_name PortalController
extends Node

@onready var _portal_transitioning: bool = false


func begin_portal_transition(source: TeleportPortal, destination: TeleportPortal, actor: AggressiveEntity) -> void:
	if _portal_transitioning:
		return

	_portal_transitioning = true

	actor.movement_controller.disable_movement(0.25)
	actor.input_controller.set_process_input(false)
	actor.input_controller.set_process_unhandled_input(false)

	actor.velocity = source.transform_velocity(actor.velocity)

	# Calculate target transform and ensure safe exit
	var target_transform: Transform3D = destination.get_exit_transform(actor.global_transform)
	target_transform = destination.find_safe_exit(actor.collision_shape.shape, target_transform)

	# Wait for physics frame to ensure proper positioning
	await actor.get_tree().physics_frame

	actor.global_transform = target_transform

	await actor.get_tree().physics_frame

	actor.input_controller.set_process_input(true)
	actor.input_controller.set_process_unhandled_input(true)

	_portal_transitioning = false
