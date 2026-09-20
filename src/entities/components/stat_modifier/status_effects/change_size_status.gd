## Can be used for gigantify or shrink
class_name ChangeSizeStatus
extends StatusEffect

@export_range(0.01, 100.0, 0.01) var scale_factor: float = 10.0

@export_range(0.01, 10.0, 0.01) var speed_multiplier: float = 1.0
@export_range(0.01, 10.0, 0.01) var jump_multiplier: float = 1.0


func get_id() -> StringName:
	return &"change_size"


func get_status_name() -> String:
	return "ChangeSize"


func on_apply(active_status: ActiveStatusEffect) -> void:
	var player: PlayerEntity = active_status.target
	var tween: Tween = player.get_tree().create_tween()
	tween.tween_property(player, "scale", player.scale * scale_factor, 1.0)
	player.movement.speed_multiplier *= speed_multiplier
	player.movement.jump_multiplier *= jump_multiplier


func on_remove(active_status: ActiveStatusEffect) -> void:
	var player: PlayerEntity = active_status.target
	var tween: Tween = player.get_tree().create_tween()
	tween.tween_property(player, "scale", player.scale / scale_factor, 1.0)
	player.movement.speed_multiplier /= speed_multiplier
	player.movement.jump_multiplier /= jump_multiplier
