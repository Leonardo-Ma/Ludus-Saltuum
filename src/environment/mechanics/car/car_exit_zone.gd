## Level trigger that returns control from a car back to player
class_name CarExitZone
extends Area3D


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	print(body)
	var car: PlayerCar = body as PlayerCar
	if car == null or not car.is_driven:
		return
	await car.exit(car.global_position)
