extends UIButton


func _button_ready() -> void:
	pass


func _button_pressed() -> void:
	if SteamWorks.steam_enabled:
		Steam.activateGameOverlayToWebPage("https://store.steampowered.com/app/4832410/Ludus_Saltuum/")
	else:
		OS.shell_open("https://store.steampowered.com/app/4832410/Ludus_Saltuum/")
