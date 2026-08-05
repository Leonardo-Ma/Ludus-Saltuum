## Helper definition to cache chunk layout data at startup without constantly instantiating
class_name ChunkData
extends RefCounted

var scene_path: String

var entrance_transform: Transform3D

var height_shift: float = 0.0
var is_turn: bool = false
var has_checkpoint: bool = false

var features: Array[ChunkFeature.Feature] = []

var required_skill_ids: Array[StringName] = []
var unlocks_skill_id: StringName = &""

var difficulty_points: int = 0
var skill_points: int = 0
var score_multiplier: float = 1.0
