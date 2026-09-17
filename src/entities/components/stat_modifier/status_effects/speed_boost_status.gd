class_name SpeedBoostStatus
extends StatusEffect

@export var bonus_speed: float = 5.0


func get_id() -> StringName:
	return &"speed_boost"


func get_status_name() -> String:
	return "Speed Boost"


func on_apply(active_status: ActiveStatusEffect) -> void:
	var player: PlayerEntity = active_status.target
	player.movement.speed += bonus_speed


func on_remove(active_status: ActiveStatusEffect) -> void:
	var player: PlayerEntity = active_status.target
	player.movement.speed -= bonus_speed
