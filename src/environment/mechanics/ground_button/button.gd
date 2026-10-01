extends Area3D

signal button_toggled_on
signal button_toggled_off

@export var _button_disable_time: float = 4.0

@onready var _button_mesh: MeshInstance3D = %ButtonMesh
@onready var _disable_timer: Timer = %DisableTimer

var _button_activated: bool = false
var _button_up_position: Vector3
var _button_down_position: Vector3


func _ready() -> void:
	_button_up_position = _button_mesh.position
	_button_down_position = _button_up_position + Vector3(0.0, -0.05, 0.0)

	_disable_timer.wait_time = _button_disable_time
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_disable_timer.timeout.connect(_on_disable_timer_timeout)


func _on_body_entered(body: Node3D) -> void:
	if not body.is_in_group(Groups.CONTROLLED):
		return

	_disable_timer.stop()

	if _button_activated:
		return

	_button_activated = true
	_button_mesh.position = _button_down_position
	button_toggled_on.emit()


func _on_body_exited(body: Node3D) -> void:
	if not body.is_in_group(Groups.CONTROLLED) or not _button_activated:
		return

	_disable_timer.start()


func _on_disable_timer_timeout() -> void:
	if not _button_activated:
		return

	_button_activated = false
	_button_mesh.position = _button_up_position
	button_toggled_off.emit()
