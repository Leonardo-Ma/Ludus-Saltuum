## Base class for all procedural level chunks
class_name LevelChunk extends Node3D

enum Difficulty { EASY, MEDIUM, HARD }

enum Skill { NONE, MULTI_JUMP, DASH, TELEPORT, SLOW_FALL }

@export_category("Difficulty")
@export var difficulty: Difficulty = Difficulty.EASY
@export var score_multiplier: float = 1.0

@export_category("Features")
@export var features: Array[ChunkFeature.Feature] = []

@export_category("Skills")
@export var unlocks_skill_id: StringName = &""
@export var required_skill_ids: Array[StringName] = []

@onready var exit_trigger: Area3D = %ExitTrigger


func _ready() -> void:
	assert(%ExitTrigger != null, "ExitTrigger missing in " + self.name)
	assert(%EntranceTrigger != null, "EntranceTrigger missing in " + self.name)
