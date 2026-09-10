## Continuous directional wind push for bodies inside its area, push direction is local +Z
class_name WindTube
extends Area3D

@export_range(1.0, 100.0, 0.5, "suffix:m/s²") var wind_force: float = 20.0
@export_range(1.0, 100.0, 0.5, "suffix:m/s") var max_wind_speed: float = 25.0

var _bodies_inside: Array[CharacterBody3D] = []


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _physics_process(delta: float) -> void:
	if _bodies_inside.is_empty():
		return

	var wind_direction: Vector3 = global_transform.basis.z.normalized()
	for body: CharacterBody3D in _bodies_inside.duplicate():
		if not is_instance_valid(body):
			_bodies_inside.erase(body)
			continue

		# Always apply upward force
		var force: Vector3 = wind_direction * wind_force * delta

		# Apply damping to prevent excessive speed
		var damping_factor: float = 0.95
		body.velocity *= damping_factor

		if body.is_in_group(Groups.PLAYERS):
			body.movement_controller.add_external_force(force)
		elif body.is_in_group(Groups.ENEMIES):
			body.navigation_controller.add_external_force(force)

		if body.velocity.length() > max_wind_speed:
			body.velocity = body.velocity.normalized() * max_wind_speed


func _on_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D:
		_bodies_inside.append(body)


func _on_body_exited(body: Node3D) -> void:
	if body is CharacterBody3D:
		_bodies_inside.erase(body)
