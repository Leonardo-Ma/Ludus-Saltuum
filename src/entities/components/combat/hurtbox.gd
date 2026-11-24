class_name Hurtbox
extends Area3D

## Upon colliding with a hitbox, triggers take damage from colliding entity, passing own attack

## Emitted after damage applied, with entity responsible for the hit
signal hit_received(hit_source: Node3D)


func _ready() -> void:
	assert(collision_layer == 0, "Hurtbox of " + owner.name + " must not have a layer") # It's in bits
	assert(collision_mask == 32768, "Hurtbox of " + owner.name + " must be in mask 16")

	area_entered.connect(_on_area_entered)


func _on_area_entered(hitbox: Hitbox) -> void:
	if hitbox == null or hitbox.ignored_entity == owner:
		return
	var attacker: Node = hitbox.get_parent()
	var attack_used: Attack = attacker.attack

	assert(attack_used != null, "Attack missing from " + attacker.name)

	owner.health.take_damage(attack_used)

	var hit_source: Node3D = hitbox.ignored_entity if hitbox.ignored_entity != null else hitbox.owner as Node3D
	hit_received.emit(hit_source)

	hitbox.hit_landed.emit(self)
