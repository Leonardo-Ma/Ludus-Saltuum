## Handles vehicle entry/exit logic [br]
## Makes player follow vehicle global transform
class_name VehicleRider
extends Node

signal vehicle_entered
signal vehicle_exited

var is_in_vehicle: bool = false

var _vehicle: PlayerCar = null

@onready var _player: PlayerEntity = owner as PlayerEntity


func _ready() -> void:
	_setup_component_connections()


func _physics_process(_delta: float) -> void:
	if not is_in_vehicle:
		return
	if not is_instance_valid(_vehicle):
		_exit_vehicle_on_invalid()
		return
	# TODO Maybe route this to movement controller?
	_player.global_position = _vehicle.global_position


func _setup_component_connections() -> void:
	vehicle_entered.connect(_on_vehicle_entered)
	vehicle_exited.connect(_on_vehicle_exited)


#region Public API
func enter_vehicle(vehicle: PlayerCar) -> void:
	assert(vehicle != null, "VehicleRider: vehicle missing in " + name)
	if is_in_vehicle:
		return
	_vehicle = vehicle
	is_in_vehicle = true
	vehicle.tree_exiting.connect(_on_vehicle_tree_exiting)
	vehicle_entered.emit()


func exit_vehicle(exit_position: Vector3) -> void:
	if not is_in_vehicle:
		return
	if is_instance_valid(_vehicle):
		_vehicle.tree_exiting.disconnect(_on_vehicle_tree_exiting)
	_player.global_position = exit_position
	_player.velocity = Vector3.ZERO
	_vehicle = null
	is_in_vehicle = false
	vehicle_exited.emit()


#endregion


#region Private API
func _on_vehicle_entered() -> void:
	_player.entity_enable_disable(false)


func _on_vehicle_exited() -> void:
	_player.entity_enable_disable(true)


func _on_vehicle_tree_exiting() -> void:
	_exit_vehicle_on_invalid()


func _exit_vehicle_on_invalid() -> void:
	_vehicle = null
	is_in_vehicle = false
	vehicle_exited.emit()
	_player.entity_enable_disable(true)
#endregion
