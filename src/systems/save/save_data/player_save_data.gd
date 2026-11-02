class_name PlayerSaveData
extends Resource

@export var score: int = 0
@export var gold: int = 0

@export var found_easter_egg_names: Array[EasterEgg.Name] = []

@export var health: int = 0

@export var unlocked_skill_ids: Array[StringName] = []

# TODO BUG Remove this from here when refactoring to decoupled save migrator system
## NOTE Save v1 only, converted to unlocked_skill_ids on load
@export var unlocked_skills: Array[SkillDefinition] = []

@export var owned_cosmetic_ids: Array[StringName] = []
@export var equipped_character_id: StringName
