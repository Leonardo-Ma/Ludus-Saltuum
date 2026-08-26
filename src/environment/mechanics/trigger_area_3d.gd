## Template for Area3D that requires collision shape to be defined on instances of this object instead of in parent scene
@abstract class_name TriggerArea3D
extends Area3D

var collision_shape_3d: CollisionShape3D


func _init() -> void:
	# BUG This is wrong
	assert(get_children().is_empty(), "Collision shape must be added as child of instance, not original parent scene")


func _ready() -> void:
	for child: Node in get_children():
		if child is CollisionShape3D:
			collision_shape_3d = child

	assert(collision_shape_3d, "Add a collision shape as first child of " + name)
	assert(collision_shape_3d.shape, "Add shape to collision of " + name)
	body_entered.connect(_on_trigger_entered)
	body_exited.connect(_on_trigger_exited)
	_child_ready()


@abstract func _child_ready() -> void

@abstract func _on_trigger_entered(body: Node3D) -> void

## Optional override
@warning_ignore("unused_parameter")  #gdlint: disable=unused-argument
func _on_trigger_exited(body: Node3D) -> void:
	pass
