extends Area3D

@export var easter_egg_name: StringName
@export var collision_shape_3d: CollisionShape3D


func _ready() -> void:
	for child: Node in get_children():
		if child is CollisionShape3D:
			collision_shape_3d = child

	assert(collision_shape_3d)  # Add a collision shape as the first child of this
	assert(collision_shape_3d.shape, "Add shape to collision of " + name)
	assert(easter_egg_name, "Easter egg name missing in " + name)
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group(Groups.CONTROLLED):
		GameEvents.easter_egg_found.emit(easter_egg_name)
