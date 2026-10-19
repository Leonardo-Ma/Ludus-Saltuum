## Bridge script to communicate with GodotSteam addon
## Exposes all project needed functions from GodotSteam's addon
# TODO Double check if checks and warnings are still needed as they won't be loaded anymore using the SteamWorks facade wrapper bridge
extends Node

signal avatar_loaded(user_id: int, avatar_size: int, avatar_buffer: PackedByteArray)

const DEMO_APP_ID: int = 5131920
const FULL_GAME_APP_ID: int = 4832410

var steam_enabled: bool = false


func initialize() -> bool:
	if steam_enabled:
		return true

	if not Engine.has_singleton("Steam"):
		push_warning("Steam missing, canceling initialization")
		# TODO Emit signal that triggers popup warning Steam failed
		return false

	if not Steam.isSteamRunning():
		push_warning("Steam not running")
		# TODO Emit signal that triggers popup warning Steam failed
		return false

	var app_id: int

	if OS.has_feature("demo"):
		app_id = DEMO_APP_ID
	else:
		app_id = FULL_GAME_APP_ID

	var steam_init: Dictionary = Steam.steamInitEx(app_id)
	print("Steam initialization: %s" % steam_init)

	if steam_init.get("status") != Steam.STEAM_API_INIT_RESULT_OK:
		push_warning("Failed to initialize Steam. Reason: %s" % steam_init.get("verbose", "Unknown"))
		# TODO Emit signal that triggers popup warning Steam failed
		return false

	steam_enabled = true

	Steam.overlay_toggled.connect(_on_overlay_toggled)
	Steam.avatar_loaded.connect(_on_avatar_loaded)

	print("Username: ", Steam.getPersonaName(), "\n")
	return true


func _process(_delta: float) -> void:
	if steam_enabled:
		Steam.run_callbacks()


func get_persona_name() -> String:
	return Steam.getPersonaName()


func request_small_avatar() -> void:
	Steam.getPlayerAvatar(Steam.AVATAR_SMALL)


func activate_overlay_to_web_page(url: String) -> void:
	Steam.activateGameOverlayToWebPage(url)


func _on_avatar_loaded(user_id: int, avatar_size: int, avatar_buffer: PackedByteArray) -> void:
	avatar_loaded.emit(user_id, avatar_size, avatar_buffer)


func _on_overlay_toggled(active: bool, _user_initiated: bool, _app_id: int) -> void:
	if active:
		ApplicationStateManager.request_pause_if_playing()

#region Cloud
func cloud_file_write(filename: String, data: PackedByteArray) -> bool:
	return Steam.fileWrite(filename, data)


func cloud_file_exists(filename: String) -> bool:
	return Steam.fileExists(filename)


func cloud_file_size(filename: String) -> int:
	return Steam.getFileSize(filename)


func cloud_file_read(filename: String, size: int) -> Dictionary:
	return Steam.fileRead(filename, size)


func cloud_file_delete(filename: String) -> bool:
	return Steam.fileDelete(filename)


func cloud_file_timestamp(filename: String) -> int:
	return Steam.getFileTimestamp(filename)
#endregion

#region Achievements
func set_achievement(api_name: String) -> bool:
	return Steam.setAchievement(api_name)


func store_stats() -> void:
	Steam.storeStats()


func get_achievement(api_name: String) -> Dictionary:
	return Steam.getAchievement(api_name)


func get_achievement_display_attribute(api_name: String, attribute: String) -> String:
	return Steam.getAchievementDisplayAttribute(api_name, attribute)


func get_achievement_icon(api_name: String) -> int:
	return Steam.getAchievementIcon(api_name)


func get_image_size(handle: int) -> Dictionary:
	return Steam.getImageSize(handle)


func get_image_rgba(handle: int) -> Dictionary:
	return Steam.getImageRGBA(handle)
#endregion
