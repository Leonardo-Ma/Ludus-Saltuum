class_name EntityNameMemory
extends GoapMemory


func init(actor: Node) -> void:
	_actor = actor
	_blackboard = {"position": _actor.position, "in_combat": false}


func _refresh_blackboard() -> void:
	var enemy_position: Vector3
	var my_position: Vector3 = _actor.global_position
	var distance: float = my_position.distance_to(enemy_position)

	var in_range: bool = distance <= 2.0

	var enemy_alive: bool
	var in_combat: bool = in_range and enemy_alive

	_blackboard["enemy_position"] = enemy_position
	_blackboard["my_position"] = my_position
	_blackboard["enemy_in_range"] = in_range
	_blackboard["enemy_alive"] = enemy_alive
	_blackboard["in_combat"] = in_combat


func get_blackboard() -> Dictionary:
	return _blackboard
