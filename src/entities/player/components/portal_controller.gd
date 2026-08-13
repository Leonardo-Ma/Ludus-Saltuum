class_name PortalController
extends Node

@onready var _portal_transitioning: bool = false


func begin_portal_transition(destination: TeleportPortal, actor: Node3D) -> void:
	if _portal_transitioning or destination.is_disabled:
		return

	_portal_transitioning = true

	actor.global_position = destination.global_position
	actor.global_rotation_degrees.y = destination.global_rotation_degrees.y

	if actor is RigidBody3D:
		actor.linear_velocity = Vector3.ZERO

	await actor.get_tree().physics_frame

	_portal_transitioning = false
