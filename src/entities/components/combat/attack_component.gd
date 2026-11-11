# TODO BUG Find better way to implement this, I can't remove existing attack resource because
# it's already properly used for hazard and other scenarios, but I can't it to a node because it's a resource
# and direct reference in class seems wrong
class_name AttackComponent
extends Node

## Component for managing entity attack configuration and execution

@export var attack: Attack


func _ready() -> void:
	assert(attack and attack.damage > 0, "Attack not properly configured for " + owner.name)
