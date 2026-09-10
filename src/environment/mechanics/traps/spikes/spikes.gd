class_name SpikeHazard
extends Hazard

@onready var spike_mesh: MeshInstance3D = $SpikeMesh
@onready var spike_mesh_initial_position: Vector3 = spike_mesh.position


func _child_ready() -> void:
	activate.connect(_on_spike_up)
	deactivate.connect(_on_spike_down)


func _on_spike_up() -> void:
	var tween: Tween = create_tween()
	tween.tween_property(spike_mesh, "position:z", 0.0, 0.2)


func _on_spike_down() -> void:
	var tween: Tween = create_tween()
	tween.tween_property(spike_mesh, "position:z", spike_mesh_initial_position.z, 0.2)
