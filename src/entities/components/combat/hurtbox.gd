class_name Hurtbox
extends Area3D

## Applies damage from overlapping hitboxes to assigned health component

## Emitted after damage applied, with entity responsible for the hit
signal hit_received(hit_source: Node3D)

@export var health: HealthComponent


func _ready() -> void:
	assert(collision_layer == 0, name + " must not have a layer") # It's in bits
	assert(collision_mask == 32768, name + " must be in mask 16")
	assert(owner is Node3D and health, "3D scene owner or health missing in " + name)

	area_entered.connect(_on_area_entered)


func _on_area_entered(hitbox: Hitbox) -> void:
	var attack_used: Attack = hitbox.attack
	if not attack_used:
		return
	var hit_source: Node3D = hitbox.source_override if hitbox.source_override else hitbox.owner
	if hit_source == owner:
		return
	assert(hit_source, "Hit source missing in " + hitbox.name + " at " + name)
	health.take_damage(attack_used)
	hit_received.emit(hit_source)

	hitbox.hit_landed.emit(self)
