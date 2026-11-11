class_name ProjectileAttackComponent
extends Node

## Component for managing projectile-based attacks

@export var projectile_attack: ProjectileAttack


func fire(target_position: Vector3, shooter: AggressiveEntity) -> void:
	assert(projectile_attack, "Projectile stats missing in " + name)
	assert(projectile_attack.projectile_scene, "Projectile scene missing in " + name)

	var projectile: Projectile = projectile_attack.projectile_scene.instantiate() as Projectile
	assert(projectile, "projectile_scene root must be Projectile in " + name)

	var origin: Vector3 = shooter.global_transform * projectile_attack.muzzle_offset
	var direction: Vector3 = origin.direction_to(target_position)

	shooter.get_tree().current_scene.add_child(projectile)
	projectile.global_position = origin
	projectile.launch(projectile_attack, shooter, direction)
