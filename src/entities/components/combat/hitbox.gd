class_name Hitbox
extends Area3D

## Used to check when a hurtbox has collided

## Emitted by Hurtbox after damage applied
@warning_ignore("unused_signal")
signal hit_landed(hurtbox: Hurtbox)

## Existing melee collision shape keyed by attack clips, optional for other hitboxes
@export var animated_shape: CollisionShape3D

## Optional variable set when a hurtbox should ignore this hit [br]
## Example: Ranged attack shouldn't hit caster
var ignored_entity: Node3D


func _ready() -> void:
	assert(collision_layer == 32768, "Hitbox of " + owner.name + " must be in layer 16") # It's in bits
	assert(collision_mask == 0, "Hitbox of " + owner.name + " must not have mask")


## Closes the collision window if a blend or interruption skips the closing key
func close_attack_window() -> void:
	assert(animated_shape != null, "Animated collision shape missing in " + name)
	animated_shape.set_deferred(&"disabled", true)
