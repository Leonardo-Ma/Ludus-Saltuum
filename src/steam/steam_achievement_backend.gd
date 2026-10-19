class_name SteamAchievementBackend
extends AchievementBackend


func is_available() -> bool:
	return SteamWorks.steam_enabled


func unlock(definition: AchievementDefinition) -> void:
	var result: bool = SteamWorks.set_achievement(definition.steam_api_name)
	assert(result, "Failed to unlock Steam achievement")
	SteamWorks.store_stats()


func is_unlocked(definition: AchievementDefinition) -> bool:
	var result: Dictionary = SteamWorks.get_achievement(definition.steam_api_name)
	assert(result.get("ret", false), "Failed to get Steam achievement")

	return result.get("achieved", false)


func get_display_name(definition: AchievementDefinition) -> String:
	var steam_name: String = SteamWorks.get_achievement_display_attribute(definition.steam_api_name, "name")
	assert(not steam_name.is_empty(), "Missing Steam achievement name")

	return steam_name


func get_description(definition: AchievementDefinition) -> String:
	var steam_description: String = SteamWorks.get_achievement_display_attribute(definition.steam_api_name, "desc")
	assert(not steam_description.is_empty(), "Missing Steam achievement description")

	return steam_description


func get_icon(definition: AchievementDefinition) -> Texture2D:
	var icon_handle: int = SteamWorks.get_achievement_icon(definition.steam_api_name)
	var icon_size: Dictionary = SteamWorks.get_image_size(icon_handle)
	var icon_buffer: Dictionary = SteamWorks.get_image_rgba(icon_handle)

	var icon_image: Image = Image.create_from_data(icon_size["width"], icon_size["height"], false, Image.FORMAT_RGBA8, icon_buffer["buffer"])

	assert(icon_image != null, "Failed to create Steam achievement icon")

	return ImageTexture.create_from_image(icon_image)
