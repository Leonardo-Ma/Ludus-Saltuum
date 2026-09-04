# https://www.youtube.com/watch?v=JWjzSn95bM0 - How to Code Melee Attacks in Godot: Hitboxes and Hurtboxes

## Used to check when a hurtbox has collided
class_name Hitbox
extends Area3D


func _ready() -> void:
	assert(collision_layer == 32768, "Hitbox of " + owner.name + " must be in layer 16") # It's in bits
	assert(collision_mask == 0, "Hitbox of " + owner.name + " must not have mask")


# TODO Remove this status manager event on damage dealt and swap for respective different type treatment
# like: acid or fire doing DoT damage
func on_hit_connected(damage_dealt: float) -> void:
	var attacker: Node = owner
	if attacker.is_in_group(Groups.ENEMIES) and attacker.status_manager:
		attacker.status_manager.dispatch_event(&"on_damage_dealt", { "damage": damage_dealt })
