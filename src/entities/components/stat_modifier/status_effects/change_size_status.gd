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


func on_apply(_target: Node) -> void:
	var player: PlayerEntity = _target.owner as PlayerEntity
	if player and not _target.has_meta("change_size_applied"):
		var tween: Tween = player.get_tree().create_tween()
		tween.tween_property(player, "scale", player.scale * scale_factor, 1.0)
		player.movement.speed *= speed_multiplier
		player.movement.jump_velocity *= jump_multiplier
		_target.set_meta("change_size_applied", true)


func on_remove(_target: Node) -> void:
	var player: PlayerEntity = _target.owner as PlayerEntity
	if player and _target.has_meta("change_size_applied"):
		var tween: Tween = player.get_tree().create_tween()
		tween.tween_property(player, "scale", player.scale / scale_factor, 1.0)
		player.movement.speed /= speed_multiplier
		player.movement.jump_velocity /= jump_multiplier
		_target.remove_meta("change_size_applied")
