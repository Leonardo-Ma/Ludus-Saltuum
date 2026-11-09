class_name Hurtbox
extends Area3D

## Upon colliding with a hitbox, triggers take damage from colliding entity, passing own attack


func _ready() -> void:
	assert(collision_layer == 0, "Hurtbox of " + owner.name + " must not have a layer") # It's in bits
	assert(collision_mask == 32768, "Hurtbox of " + owner.name + " must be in mask 16")

	area_entered.connect(_on_area_entered)


func _on_area_entered(hitbox: Hitbox) -> void:
	if hitbox == null or hitbox.ignored_entity == owner:
		return
	var attacker: Node = hitbox.get_parent()
	var attack_used: Attack = attacker.attack

	owner.health.take_damage(attack_used)
	hitbox.hit_landed.emit(self)

	print(owner.name, " Hurt by ", hitbox.owner.name, " For ", attack_used.damage)
