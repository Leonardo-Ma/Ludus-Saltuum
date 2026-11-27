class_name SpeedBoostStatus
extends StatusEffect

const TRAIL_COLOR: Color = Color(0.3, 0.6, 1.0, 0.8)

@export var bonus_speed: float = 5.0


func get_id() -> StringName:
	return &"speed_boost"


func get_status_name() -> String:
	return "Speed Boost"


func on_apply(active_status: ActiveStatusEffect) -> void:
	_apply_boost(active_status, bonus_speed, true)


func on_remove(active_status: ActiveStatusEffect) -> void:
	_apply_boost(active_status, -bonus_speed, false)


func _apply_boost(active_status: ActiveStatusEffect, speed_delta: float, trail_enabled: bool) -> void:
	var player: PlayerEntity = active_status.target
	var movement: PlayerMovementComponent = player.get_node(^"%PlayerMovementComponent")
	var vfx: VFXController = player.get_node(^"%VFXController")
	assert(movement and vfx, "Speed boost dependencies missing in " + player.name)
	movement.speed_bonus += speed_delta
	vfx.set_trail(get_id(), trail_enabled, TRAIL_COLOR)
