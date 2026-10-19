## NOTE This is wrapper to allow the game not to be directly coupled to Steam addon
## https://refactoring.guru/design-patterns/facade
## The steam princess is at steamworks_desktop
extends Node

signal avatar_loaded(user_id: int, avatar_size: int, avatar_buffer: PackedByteArray)

var steam_enabled: bool = false

# TODO Consider adding a steam provider abstract script and change the type to that
var _provider: Node


func _ready() -> void:
	if OS.has_feature("web"):
		return

	# Load dynamically so Web never loads script that references Steam
	var provider_script: Script = load("uid://cptuee0vgr7wl") # steamworks_desktop.gd
	_provider = provider_script.new()
	add_child(_provider)

	_provider.avatar_loaded.connect(_on_avatar_loaded)
	steam_enabled = _provider.initialize()


func get_persona_name() -> String:
	if not steam_enabled:
		return ""

	return _provider.get_persona_name()


func request_small_avatar() -> void:
	if steam_enabled:
		_provider.request_small_avatar()


func activate_overlay_to_web_page(url: String) -> void:
	if steam_enabled:
		_provider.activate_overlay_to_web_page(url)


func _on_avatar_loaded(user_id: int, avatar_size: int, avatar_buffer: PackedByteArray) -> void:
	avatar_loaded.emit(user_id, avatar_size, avatar_buffer)

#region Cloud
func cloud_file_write(filename: String, data: PackedByteArray) -> bool:
	if not steam_enabled:
		return false
	return _provider.cloud_file_write(filename, data)


func cloud_file_exists(filename: String) -> bool:
	if not steam_enabled:
		return false
	return _provider.cloud_file_exists(filename)


func cloud_file_size(filename: String) -> int:
	if not steam_enabled:
		return 0
	return _provider.cloud_file_size(filename)


func cloud_file_read(filename: String, size: int) -> Dictionary:
	if not steam_enabled:
		return { "ret": false, "buf": PackedByteArray() }
	return _provider.cloud_file_read(filename, size)


func cloud_file_delete(filename: String) -> bool:
	if not steam_enabled:
		return false
	return _provider.cloud_file_delete(filename)


func cloud_file_timestamp(filename: String) -> int:
	if not steam_enabled:
		return 0
	return _provider.cloud_file_timestamp(filename)
#endregion

#region Achievements
func set_achievement(api_name: String) -> bool:
	if not steam_enabled:
		return false
	return _provider.set_achievement(api_name)


func store_stats() -> void:
	if steam_enabled:
		_provider.store_stats()


func get_achievement(api_name: String) -> Dictionary:
	if not steam_enabled:
		return { "ret": false, "achieved": false }
	return _provider.get_achievement(api_name)


func get_achievement_display_attribute(api_name: String, attribute: String) -> String:
	if not steam_enabled:
		return ""
	return _provider.get_achievement_display_attribute(api_name, attribute)


func get_achievement_icon(api_name: String) -> int:
	if not steam_enabled:
		return 0
	return _provider.get_achievement_icon(api_name)


func get_image_size(handle: int) -> Dictionary:
	if not steam_enabled:
		return { "width": 0, "height": 0 }
	return _provider.get_image_size(handle)


func get_image_rgba(handle: int) -> Dictionary:
	if not steam_enabled:
		return { "buffer": PackedByteArray() }
	return _provider.get_image_rgba(handle)
#endregion
