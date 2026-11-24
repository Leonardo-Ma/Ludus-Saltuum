class_name LevelChunkContainer
extends Node3D

## Registers the scene's procedural chunk mount after authored entities are ready


func _enter_tree() -> void:
	assert(owner != null, "Scene owner missing in " + name)
	if owner.is_node_ready():
		_register()
	else:
		owner.ready.connect(_register, CONNECT_ONE_SHOT)


func _exit_tree() -> void:
	if owner != null and owner.ready.is_connected(_register):
		owner.ready.disconnect(_register)
	ChunkManager.unregister_chunk_container(self)


func _register() -> void:
	var valid_ids: bool = WorldSaveController.has_valid_entity_ids()
	assert(valid_ids, "Persistent entity IDs must be nonempty and unique in " + name)
	if not valid_ids:
		get_tree().quit(1)
		return
	ChunkManager.register_chunk_container(self)
