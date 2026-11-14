class_name ProjectileAttackComponent
extends Node

## Component for managing projectile-based attacks

@export var projectile_attack: ProjectileAttack


func fire(target_position: Vector3, shooter: AggressiveEntity) -> void:
	fire_direction(_get_muzzle_position(shooter).direction_to(target_position), shooter)


func fire_direction(direction: Vector3, shooter: AggressiveEntity) -> void:
	assert(projectile_attack.projectile_scene, "Projectile scene missing in " + name)

	var projectile: Projectile = projectile_attack.projectile_scene.instantiate() as Projectile
	assert(projectile, "projectile_scene root must be Projectile in " + name)

	shooter.get_tree().current_scene.add_child(projectile)
	projectile.global_position = _get_muzzle_position(shooter)
	projectile.launch(projectile_attack, shooter, direction)


## Shooter transform includes scale, so offset follows gigantify / shrink
func _get_muzzle_position(shooter: AggressiveEntity) -> Vector3:
	assert(projectile_attack, "Projectile stats missing in " + name)
	return shooter.global_transform * projectile_attack.muzzle_offset
