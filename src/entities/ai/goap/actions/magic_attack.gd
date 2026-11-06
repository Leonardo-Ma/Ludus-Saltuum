class_name MagicAttack
extends GoapAction

const AIM_HEIGHT: float = 1.0

var _cooldown_timer: SceneTreeTimer = null


func get_custom_class_name() -> String:
	return "MagicAttack"


func is_valid(_blackboard: Dictionary) -> bool:
	return _blackboard.get("in_combat", false) == true


func get_cost(_blackboard: Dictionary) -> int:
	return 1


func get_preconditions() -> Dictionary:
	return { "enemy_in_ranged_range": true, "enemy_alive": true }


func get_effects() -> Dictionary:
	return { "enemy_alive": false }


func perform(_actor: Node, _delta: float, _blackboard: Dictionary) -> bool:
	var entity: AggressiveEntity = _actor as AggressiveEntity
	assert(
		entity != null and entity.projectile_attack != null and entity.projectile_attack.projectile_scene != null,
		"projectile_attack missing in " + _actor.name,
	)
	entity.npc_movement_controller.stop()
	entity.goap_controller.force_refresh_blackboard()

	var enemy_position: Vector3 = _blackboard.get("enemy_position", entity.global_position)
	var direction: Vector3 = entity.global_position.direction_to(enemy_position)
	direction.y = 0.0
	if direction.length_squared() > 0.001:
		var target_rotation_y: float = atan2(direction.x, direction.z)
		entity.global_rotation.y = lerp_angle(entity.global_rotation.y, target_rotation_y, 10.0 * _delta)

	if _cooldown_timer != null and _cooldown_timer.time_left > 0.0:
		return false

	entity.magic_casted.emit()
	_spawn_projectile(entity, enemy_position)
	_cooldown_timer = entity.get_tree().create_timer(entity.projectile_attack.rate, false)
	return true


func _spawn_projectile(entity: AggressiveEntity, enemy_position: Vector3) -> void:
	var projectile_attack: ProjectileAttack = entity.projectile_attack
	var projectile: Projectile = projectile_attack.projectile_scene.instantiate() as Projectile
	assert(projectile != null, "projectile_scene root must be Projectile in " + entity.name)
	assert(projectile_attack != null, "Projectile attack missing for " + entity.name)

	var origin: Vector3 = entity.global_transform * projectile_attack.muzzle_offset
	var direction: Vector3 = origin.direction_to(enemy_position + Vector3.UP * AIM_HEIGHT)

	entity.get_tree().current_scene.add_child(projectile)
	projectile.global_position = origin
	projectile.launch(projectile_attack, entity, direction)
