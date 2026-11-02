extends Node3D

@onready var visual: Node3D = %Visual


func _ready() -> void:
	var mesh: PackedScene = owner.chosen_character.character_mesh
	set_character(mesh)


func set_character(character_scene: PackedScene) -> void:
	for child: Node in visual.get_children():
		visual.remove_child(child)
		child.queue_free()

	var instance: Node3D = character_scene.instantiate() as Node3D
	assert(instance != null, "Character scene root must be Node3D in " + self.name)

	visual.add_child(instance)
