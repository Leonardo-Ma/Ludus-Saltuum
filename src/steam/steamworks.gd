extends Node

const DEMO_APP_ID: int = 5131920
const FULL_GAME_APP_ID: int = 4832410

var steam_enabled: bool


func _ready() -> void:
	if not Engine.has_singleton("Steam"):
		push_warning("Steam missing, canceling initialization")
		# TODO Emit a signal error that triggers popup warning steam failed
		steam_enabled = false
		return

	if not Steam.isSteamRunning():
		push_warning("Steam not running")
		# TODO Emit a signal error that triggers popup warning steam failed
		steam_enabled = false
		return

	var try_init_steam: Dictionary

	if OS.is_debug_build():
		if OS.has_feature("demo"):
			try_init_steam = Steam.steamInitEx(DEMO_APP_ID)
		else:
			try_init_steam = Steam.steamInitEx(FULL_GAME_APP_ID)

	print("Steam initialization: %s" % try_init_steam)

	if try_init_steam['status'] != Steam.STEAM_API_INIT_RESULT_OK:
		push_warning("Failed to initialize Steam. Reason: %s" % try_init_steam.get('verbose'))
		# TODO Emit a signal error that triggers popup warning steam failed
		steam_enabled = false
		return

	var steam_player_name: String = Steam.getPersonaName()
	print("Username: ", steam_player_name + "\n")


func _process(_delta: float) -> void:
	if steam_enabled:
		Steam.run_callbacks()
