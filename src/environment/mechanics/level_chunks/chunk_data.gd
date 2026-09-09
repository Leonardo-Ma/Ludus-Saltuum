## Helper definition to cache chunk layout data at startup without constantly instantiating
class_name ChunkData
extends RefCounted

var scene_path: String
## Resource UID text, stable persistence key independent of _all_chunks ordering
var scene_uid: String = ""

var entrance_transform: Transform3D

var height_shift: float = 0.0
var is_turn: bool = false
var has_checkpoint: bool = false

var features: Array[ChunkFeature.Feature] = []

var required_skill: Array[SkillDefinition] = []
var unlocks_skill: SkillDefinition

var difficulty_points: int = 0
var skill_points: int = 0
var score_multiplier: float = 1.0
