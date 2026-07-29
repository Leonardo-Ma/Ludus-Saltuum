## To be attached to entities that may receive knockback
class_name KnockbackController
extends Node

@export_category("Knockback Settings")
@export var friction: float = 20.0
@export var min_velocity: float = 0.5

var _current_knockback: Vector3 = Vector3.ZERO
var _hurtbox: Hurtbox = null


func _ready() -> void:
	_hurtbox = owner.get_node("%Hurtbox")
	_hurtbox.knockback_received.connect(_on_knockback_received)

	# Start inactive, only runs when knockback is applied
	set_physics_process(false)


# TODO Improve this
func apply_knockback(impulse: Vector3) -> void:
	if impulse.length_squared() > 0.01:
		# Add to existing knockback to allow combo juggling/multihits
		_current_knockback += impulse

		# Estimate duration based on friction slowing to 0 using the new total magnitude
		var duration: float = _current_knockback.length() / friction

		if owner.is_in_group(Groups.PLAYERS):
			owner.movement_controller.disable_movement(duration)
		elif owner.is_in_group(Groups.ENEMIES):
			owner.navigation_controller.disable_movement(duration)

		set_physics_process(true)


func _on_knockback_received(knockback_velocity: Vector3) -> void:
	apply_knockback(knockback_velocity)


func _physics_process(delta: float) -> void:
	var body: CharacterBody3D = owner as CharacterBody3D

	if _current_knockback.length_squared() < (min_velocity * min_velocity):
		_current_knockback = Vector3.ZERO
		body.velocity = Vector3.ZERO
		set_physics_process(false)
		return

	_current_knockback = _current_knockback.move_toward(Vector3.ZERO, friction * delta)

	# Preserve gravity handling by retaining vertical velocity
	var current_y: float = body.velocity.y
	body.velocity = _current_knockback
	body.velocity.y = current_y

	var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
	if not body.is_on_floor():
		body.velocity.y -= gravity * delta

	body.move_and_slide()
