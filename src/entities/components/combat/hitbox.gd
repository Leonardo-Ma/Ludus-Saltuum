class_name Hitbox
extends Area3D

## Used to check when a hurtbox has collided

## Emitted by Hurtbox after damage applied
@warning_ignore("unused_signal")
signal hit_landed(hurtbox: Hurtbox)

## Optional variable set when a hurtbox should ignore this hit [br]
## Example: Ranged attack shouldn't hit caster
var ignored_entity: Node3D


func _ready() -> void:
	assert(collision_layer == 32768, "Hitbox of " + owner.name + " must be in layer 16") # It's in bits
	assert(collision_mask == 0, "Hitbox of " + owner.name + " must not have mask")
