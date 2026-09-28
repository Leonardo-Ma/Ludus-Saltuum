class_name RedTorchTrigger
extends TriggerArea3D

signal red_torch_triggered


func _child_ready() -> void:
	pass


func _on_trigger_entered(body: Node3D) -> void:
	if body.is_in_group(Groups.CONTROLLED):
		red_torch_triggered.emit()
