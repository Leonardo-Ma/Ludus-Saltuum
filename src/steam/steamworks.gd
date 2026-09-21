extends Node

const DEMO_APP_ID: int = 5131920
const FULL_GAME_APP_ID: int = 4832410

var steam_enabled: bool = false


func _ready() -> void:
	if not Engine.has_singleton("Steam"):
		push_warning("Steam missing, canceling initialization")
		# TODO Emit signal that triggers popup warning Steam failed
		return

	if not Steam.isSteamRunning():
		push_warning("Steam not running")
		# TODO Emit signal that triggers popup warning Steam failed
		return

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
		return

	steam_enabled = true

	var steam_player_name: String = Steam.getPersonaName()
	print("Username: ", steam_player_name + "\n")


func _process(_delta: float) -> void:
	if steam_enabled:
		Steam.run_callbacks()
