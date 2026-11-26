class_name WorldSaveData
extends Resource

## Version of collected and defeated entity keys
@export var entity_id_version: int = 0
@export var collected_collectible_ids: Dictionary[StringName, bool] = { }
@export var killed_enemy_ids: Dictionary[StringName, bool] = { }
