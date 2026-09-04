class_name MeleeAttack
extends GoapAction

var _attack_cooldown: float = 1.8
var _last_attack_time: int = 0


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
	_actor.navigation_controller.stop()

	var enemy_pos: Vector3 = _blackboard.get("enemy_position", _actor.global_position)
	var direction: Vector3 = _actor.global_position.direction_to(enemy_pos)
	direction.y = 0.0

	if direction.length_squared() > 0.001:
		direction = direction.normalized()
		var target_rotation_y: float = atan2(direction.x, direction.z)
		_actor.global_rotation.y = lerp_angle(_actor.global_rotation.y, target_rotation_y, 10.0 * _delta)

	var current_time: int = Time.get_ticks_msec()

	if current_time - _last_attack_time >= int(_attack_cooldown * 1000.0):
		_actor.melee_attacked.emit()
		_last_attack_time = current_time
		return true
	return false
