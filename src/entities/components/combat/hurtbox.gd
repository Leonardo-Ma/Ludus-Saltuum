# https://www.youtube.com/watch?v=JWjzSn95bM0 GDQuest - How to Code Melee Attacks in Godot: Hitboxes and Hurtboxes
# https://www.youtube.com/watch?v=y3faMdIb2II Bitlytic - Maximize Your Game Development Potential with Classes in Godot (class_name is OP)

## Upon colliding with a hitbox, triggers take damage from colliding entity, passing own attack
class_name Hurtbox
extends Area3D

signal knockback_received(knockback_velocity: Vector3)


func _ready() -> void:
	assert(collision_layer == 0, "Hurtbox of " + owner.name + " must not have a layer") # It's in bits
	assert(collision_mask == 32768, "Hurtbox of " + owner.name + " must be in mask 16")

	area_entered.connect(_on_area_entered)


func _on_area_entered(hitbox: Hitbox) -> void:
	if hitbox == null:
		return
	var attacker: Node = hitbox.get_parent()
	var attack_used: Attack = attacker.attack
	owner.health.take_damage(attack_used)
	print(owner.name, " Hurt by ", hitbox.owner.name, " For ", attack_used.damage)

	hitbox.on_hit_connected(float(attack_used.damage))

	if attack_used.knockback_force > 0:
		var direction: Vector3 = owner.global_position.direction_to(hitbox.owner.global_position)
		direction.y = 0
		# TODO Consider passing this as Attack parameter? (knockback bool push/pull)
		# Invert direction to push away
		var knockback_velocity: Vector3 = -direction.normalized() * attack_used.knockback_force
		knockback_received.emit(knockback_velocity)
