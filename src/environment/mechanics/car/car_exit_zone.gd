## Level trigger that returns control from a car back to player
class_name CarExitZone
extends TriggerArea3D


func _child_ready() -> void:
	pass


func _on_trigger_entered(body: Node3D) -> void:
	var car: PlayerCar = body as PlayerCar
	if car == null or not car.is_driven:
		return
	await car.exit(car.global_position)
