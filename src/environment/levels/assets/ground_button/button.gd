extends Area3D

signal button_toggled_on
signal button_toggled_off

const DOOR_CLOSE_TIME: int = 4
@onready var button_mesh: MeshInstance3D = $ButtonMesh


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(_body: Node3D) -> void:
	if _body.is_in_group(Groups.PLAYERS):
		button_toggled_on.emit()
		set_deferred("monitoring", false)
		button_mesh.global_position.y -= 0.120
		await get_tree().create_timer(DOOR_CLOSE_TIME).timeout
		button_mesh.global_position.y += 0.120
		set_deferred("monitoring", true)
		button_toggled_off.emit()
