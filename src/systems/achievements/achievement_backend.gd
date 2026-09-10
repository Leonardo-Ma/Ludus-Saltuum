## Interface for achievement unlock/query backends
@abstract class_name AchievementBackend
extends RefCounted


@abstract func is_available() -> bool


@abstract func unlock(definition: AchievementDefinition) -> void


@abstract func is_unlocked(definition: AchievementDefinition) -> bool


@abstract func get_display_name(definition: AchievementDefinition) -> String


@abstract func get_description(definition: AchievementDefinition) -> String


@abstract func get_icon(definition: AchievementDefinition) -> Texture2D
