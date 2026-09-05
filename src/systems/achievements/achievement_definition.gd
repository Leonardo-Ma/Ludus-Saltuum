## Local fallback data for single achievement, mirrors optional Steam entry
class_name AchievementDefinition
extends Resource

@export var key: StringName = &""
@export var steam_api_name: String = ""
@export var display_name: String = ""
@export var description: String = ""
@export var icon_locked: Texture2D
@export var icon_unlocked: Texture2D
## Score threshold for progress sorting, -1 if not score-based
@export var unlock_threshold: int = -1
