class_name SpeedBoostStatus
extends StatusEffect

const TRAIL_COLOR: Color = Color(0.3, 0.6, 1.0, 0.8)

@export var bonus_speed: float = 5.0


func get_id() -> StringName:
	return &"speed_boost"


func get_status_name() -> String:
	return "Speed Boost"


func on_apply(active_status: ActiveStatusEffect) -> void:
	var player: PlayerEntity = active_status.target
	player.movement.speed_bonus += bonus_speed
	player.vfx_controller.set_trail(get_id(), true, TRAIL_COLOR)


func on_remove(active_status: ActiveStatusEffect) -> void:
	var player: PlayerEntity = active_status.target
	player.movement.speed_bonus -= bonus_speed
	player.vfx_controller.set_trail(get_id(), false, TRAIL_COLOR)
