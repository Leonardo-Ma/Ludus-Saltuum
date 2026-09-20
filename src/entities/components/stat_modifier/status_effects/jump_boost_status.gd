class_name JumpBoostStatus
extends StatusEffect

@export var bonus_speed: float = 5.0


func get_id() -> StringName:
	return &"jump_boost"


func get_status_name() -> String:
	return "Jump Boost"


func on_apply(active_status: ActiveStatusEffect) -> void:
	var player: PlayerEntity = active_status.target
	player.movement.jump_bonus += bonus_speed


func on_remove(active_status: ActiveStatusEffect) -> void:
	var player: PlayerEntity = active_status.target
	player.movement.jump_bonus -= bonus_speed
