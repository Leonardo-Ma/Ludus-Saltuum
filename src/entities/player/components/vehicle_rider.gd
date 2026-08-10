## Handles vehicle entry/exit logic
class_name VehicleRider
extends Node

signal vehicle_entered
signal vehicle_exited

var _is_possessing_vehicle: bool = false

@onready var _player: PlayerEntity = owner as PlayerEntity
@onready var _visual: Node3D = %Visual
@onready var _default_visual_scale: Vector3 = _visual.scale if _visual else Vector3.ONE


func _ready() -> void:
	_setup_component_connections()


func _setup_component_connections() -> void:
	vehicle_entered.connect(_on_vehicle_entered)
	vehicle_exited.connect(_on_vehicle_exited)


#region Public API
func enter_vehicle() -> void:
	if _is_possessing_vehicle:
		return

	_is_possessing_vehicle = true
	vehicle_entered.emit()

	# Visual shrink effect
	if _visual:
		var tween: Tween = _player.create_tween()
		tween.tween_property(_visual, "scale", _default_visual_scale * 0.001, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)


func exit_vehicle(exit_position: Vector3) -> void:
	if not _is_possessing_vehicle:
		return

	_player.global_position = exit_position
	_player.velocity = Vector3.ZERO

	if _visual:
		_visual.scale = Vector3.ZERO

	_is_possessing_vehicle = false
	vehicle_exited.emit()

	# Visual grow effect
	if _visual:
		var tween: Tween = _player.create_tween()
		tween.tween_property(_visual, "scale", _default_visual_scale, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


#endregion


#region Private API
func _on_vehicle_entered() -> void:
	_player.entity_enable_disable(false)
	_player.add_to_group(Groups.PLAYERS)


func _on_vehicle_exited() -> void:
	_player.entity_enable_disable(true)
	_player.remove_from_group(Groups.PLAYERS)

	GameEvents.set_controlled_entity(_player)
#endregion
