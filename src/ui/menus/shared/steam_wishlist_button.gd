extends UIButton

const STORE_URL: String = "https://store.steampowered.com/app/4832410/Ludus_Saltuum/"


func _button_ready() -> void:
	pass


func _button_pressed() -> void:
	if SteamWorks.steam_enabled:
		SteamWorks.activate_overlay_to_web_page(STORE_URL)
	else:
		OS.shell_open(STORE_URL)
