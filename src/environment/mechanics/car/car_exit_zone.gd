## Level trigger that returns control from a car back to player
class_name CarExitZone
extends Area3D

@onready var collision_shape_3d: CollisionShape3D


func _init() -> void:
	assert(get_children().is_empty())


func _ready() -> void:
	for child: Node in get_children():
		if child is CollisionShape3D:
			collision_shape_3d = child

	assert(collision_shape_3d)  # Add a collision shape as the first child of this
	assert(collision_shape_3d.shape, "Add shape to collision of " + name)
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	var car: PlayerCar = body as PlayerCar
	if car == null or not car.is_driven:
		return
	await car.exit(car.global_position)
