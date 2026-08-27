extends Area3D

@export var target_gameplay_mode: GameplayStateManager.GameplayMode

@export var collision_shape_3d: CollisionShape3D


func _ready() -> void:
	assert(collision_shape_3d.shape, "Add a collision shape as child of " + name)
	assert(collision_shape_3d.owner != self, "Collision shape must be added as child of an instance of " + name + ". Not in the parent class")
	assert(collision_shape_3d in get_children(), "Add a collision shape as child of " + name)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group(Groups.CONTROLLED):
		GameplayStateManager.change_gameplay_state(target_gameplay_mode)


func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group(Groups.CONTROLLED):
		GameplayStateManager.change_gameplay_state(GameplayStateManager.get_previous_mode())
