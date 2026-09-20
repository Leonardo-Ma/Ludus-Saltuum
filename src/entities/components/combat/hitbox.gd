# https://www.youtube.com/watch?v=JWjzSn95bM0 - How to Code Melee Attacks in Godot: Hitboxes and Hurtboxes
## Used to check when a hurtbox has collided
class_name Hitbox
extends Area3D


func _ready() -> void:
	assert(collision_layer == 32768, "Hitbox of " + owner.name + " must be in layer 16") # It's in bits
	assert(collision_mask == 0, "Hitbox of " + owner.name + " must not have mask")
