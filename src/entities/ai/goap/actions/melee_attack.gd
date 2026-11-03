class_name MeleeAttack
extends GoapAction

const ATTACK_COOLDOWN: float = 1.8
var _cooldown_timer: SceneTreeTimer = null


func get_custom_class_name() -> String:
	return "MeleeAttack"


func is_valid(_blackboard: Dictionary) -> bool:
	return _blackboard.get("in_combat", false) == true


func get_cost(_blackboard: Dictionary) -> int:
	return 1


func get_preconditions() -> Dictionary:
	return { "enemy_in_melee_range": true, "enemy_alive": true }


func get_effects() -> Dictionary:
	return { "enemy_alive": false }


func perform(_actor: Node, _delta: float, _blackboard: Dictionary) -> bool:
	_actor.npc_movement_controller.stop()

	var enemy_pos: Vector3 = _blackboard.get("enemy_position", _actor.global_position)
	var direction: Vector3 = _actor.global_position.direction_to(enemy_pos)
	direction.y = 0.0

	if direction.length_squared() > 0.001:
		direction = direction.normalized()
		var target_rotation_y: float = atan2(direction.x, direction.z)
		_actor.global_rotation.y = lerp_angle(_actor.global_rotation.y, target_rotation_y, 10.0 * _delta)

	if _cooldown_timer == null or _cooldown_timer.time_left <= 0.0:
		_actor.melee_attacked.emit()
		_cooldown_timer = _actor.get_tree().create_timer(ATTACK_COOLDOWN, false)
		return true
	return false
