## Data to be persistent, one resource per save slot
class_name SaveData
extends Resource

@export var save_version: int = 1
@export var slot_index: int = 0
@export var is_auto_save: bool = false
@export var save_timestamp: int = 0

@export var player: PlayerSaveData = PlayerSaveData.new()
@export var world: WorldSaveData = WorldSaveData.new()
@export var chunks: ChunkSaveData = ChunkSaveData.new()
@export var checkpoint: CheckpointSaveData = CheckpointSaveData.new()
