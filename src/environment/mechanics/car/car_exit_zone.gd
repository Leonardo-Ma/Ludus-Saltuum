## Level trigger that returns control from a car back to player
class_name CarExitZone
extends Area3D

@onready var collision_shape_3d: CollisionShape3D


func _init() -> void:
	assert(get_children().is_empty())


func _ready() -> void:
	collision_shape_3d = get_child(0)
	assert(collision_shape_3d)  # Add a collision shape as child and the only child of this
	assert(collision_shape_3d.shape, "Add a collision shape as child of " + name + " in " + str(owner))
	assert(collision_shape_3d in get_children(), "Add a collision shape as child of " + name + " in " + str(owner))
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	var car: PlayerCar = body as PlayerCar
	if car == null or not car.is_driven:
		return
	await car.exit(car.global_position)
