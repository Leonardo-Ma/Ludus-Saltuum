class_name AchievementDefinition
extends Resource

## Local fallback data for single achievement, mirrors optional Steam entry

## Persisted as lower case name in achievements.cfg [br]
## NOTE Never rename or reuse
enum Id {
	UNDEFINED = 0,
	FIRST_RUN = 1,
	SCORE_100 = 2,
	SCORE_500 = 3,
	SCORE_2000 = 4,
	SCORE_10000 = 5,
	FIRST_EASTER_EGG = 6,
	ALL_SKILLS = 7,
}

@export var id: Id = Id.UNDEFINED
@export var steam_api_name: String = ""
@export var display_name: String = ""
@export var description: String = ""
@export var icon_locked: Texture2D
@export var icon_unlocked: Texture2D
## Score threshold for progress sorting, -1 if not score-based
@export var unlock_threshold: int = -1
