extends Node


func _ready() -> void:
	var is_steam_running: bool = Steam.isSteamRunning()

	if !is_steam_running:
		push_warning("Steam not running")
		return

	if OS.is_debug_build():
		if OS.has_feature("demo"):
			Steam.steamInitEx(5131920)
		else:
			Steam.steamInitEx(4832410)

	# TODO There are better ways to check as the game could have been family shared or free weekend...
	#var is_valid_license: bool = Steam.userHasLicenseForApp(Steam.getSteamID(), Steam.getAppID())
	#if !is_valid_license:
	#	push_error("Player didn't purchase the game")
	#	return

	var steam_player_name: String = Steam.getPersonaName()
	print("Username: ", steam_player_name + "\n")


func _process(_delta: float) -> void:
	Steam.run_callbacks()
