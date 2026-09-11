class_name SteamAchievementBackend
extends AchievementBackend


func is_available() -> bool:
	return SteamWorks.steam_enabled


func unlock(definition: AchievementDefinition) -> void:
	var result: bool = Steam.setAchievement(definition.steam_api_name)
	assert(result, "Failed to unlock Steam achievement")
	Steam.storeStats()


func is_unlocked(definition: AchievementDefinition) -> bool:
	var result: Dictionary = Steam.getAchievement(definition.steam_api_name)
	assert(result.get("ret", false), "Failed to get Steam achievement")

	return result.get("achieved", false)


func get_display_name(definition: AchievementDefinition) -> String:
	var steam_name: String = Steam.getAchievementDisplayAttribute(definition.steam_api_name, "name")
	assert(not steam_name.is_empty(), "Missing Steam achievement name")

	return steam_name


func get_description(definition: AchievementDefinition) -> String:
	var steam_description: String = Steam.getAchievementDisplayAttribute(definition.steam_api_name, "desc")
	assert(not steam_description.is_empty(), "Missing Steam achievement description")

	return steam_description


func get_icon(definition: AchievementDefinition) -> Texture2D:
	var icon_handle: int = Steam.getAchievementIcon(definition.steam_api_name)
	var icon_size: Dictionary = Steam.getImageSize(icon_handle)
	var icon_buffer: Dictionary = Steam.getImageRGBA(icon_handle)

	var icon_image: Image = Image.create_from_data(icon_size["width"], icon_size["height"], false, Image.FORMAT_RGBA8, icon_buffer["buffer"])

	assert(icon_image != null, "Failed to create Steam achievement icon")

	return ImageTexture.create_from_image(icon_image)
