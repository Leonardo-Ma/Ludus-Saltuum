class_name Hitbox
extends Area3D

## Reports contact between an active attack and a hurtbox

## Emitted by Hurtbox after damage applied
@warning_ignore("unused_signal")
signal hit_landed(hurtbox: Hurtbox)

## Existing melee collision shape keyed by attack clips, optional for other hitboxes
@export var animated_shape: CollisionShape3D

## NOTE Optional. Overrides scene owner for hit attribution and self-hit filtering [br]
## Example: projectile source is its caster
var source_override: Node3D
var attack: Attack


func _ready() -> void:
	assert(collision_layer == 32768, name + " must be in layer 16") # It's in bits
	assert(collision_mask == 0, name + " must not have mask")


## Assigns damage data when a swing, projectile, or hazard is ready to hit
func arm(attack_used: Attack) -> void:
	assert(owner is Node3D and attack_used, "3D scene owner or attack missing in " + name)
	attack = attack_used


## Closes the collision window if a blend or interruption skips the closing key
func close_attack_window() -> void:
	assert(animated_shape, "Animated collision shape missing in " + name)
	attack = null
	animated_shape.set_deferred(&"disabled", true)
