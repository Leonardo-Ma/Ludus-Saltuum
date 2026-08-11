extends Area3D

@export var easter_egg_name: StringName
@export var collision_shape_3d: CollisionShape3D


func _ready() -> void:
	collision_shape_3d = get_child(0)
	assert(collision_shape_3d)  # Add a collision shape as child and the only child of this
	assert(collision_shape_3d.shape, "Add a collision shape as child of " + name)
	assert(collision_shape_3d in get_children(), "Add a collision shape as child of " + name)
	assert(easter_egg_name, "Easter egg name missing in " + name)
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group(Groups.CONTROLLED):
		GameEvents.easter_egg_found.emit(easter_egg_name)
