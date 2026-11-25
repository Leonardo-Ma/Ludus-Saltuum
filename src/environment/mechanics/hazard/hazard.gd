@abstract class_name Hazard
extends Area3D

signal activate
signal deactivate

@export var attack: Attack
@export var hitbox_shape: CollisionShape3D

@onready var hitbox: Hitbox = %Hitbox


## Children should override this instead of _ready()
@abstract func _child_ready() -> void


func _ready() -> void:
	assert(attack, "Attack missing in " + name)
	assert(hitbox and hitbox_shape, "Hitbox or collision shape missing in " + name)
	if !attack.hitkill:
		assert(attack.damage > 0, "Attack property incorrect for " + name)
	hitbox.arm(attack)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	_child_ready()


func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group(Groups.CONTROLLED) or body.is_in_group(Groups.ENEMIES):
		hitbox_shape.set_deferred(&"disabled", false)
		activate.emit()


func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group(Groups.CONTROLLED) or body.is_in_group(Groups.ENEMIES):
		hitbox_shape.set_deferred(&"disabled", true)
		deactivate.emit()
