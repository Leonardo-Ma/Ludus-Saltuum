class_name PortalController
extends Node

@onready var _portal_transitioning: bool = false


func begin_portal_transition(destination: TeleportPortal, actor: Node3D) -> void:
	if _portal_transitioning or destination.is_disabled:
		return

	_portal_transitioning = true

	actor.global_position = destination.global_position

	await actor.get_tree().physics_frame

	_portal_transitioning = false
