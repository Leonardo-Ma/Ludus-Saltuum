extends CheckButton


func _ready() -> void:
	if not SteamWorks.steam_enabled:
		visible = false
