extends HSlider


func _ready() -> void:
	value = SettingsManager.mouse_sensitivity_horizontal
	value_changed.connect(_on_value_changed)
	SettingsManager.settings_reset.connect(_on_settings_reset)


func _on_value_changed(new_value: float) -> void:
	SettingsManager.mouse_sensitivity_horizontal = new_value
	SettingsManager.mouse_sensitivity_vertical = new_value
	SettingsManager.save()
	_apply_to_active_player()


func _on_settings_reset() -> void:
	value = SettingsManager.mouse_sensitivity_horizontal


func _apply_to_active_player() -> void:
	var players: Array[Node] = get_tree().get_nodes_in_group(Groups.PLAYERS)
	assert(players.size() > 0, "Player missing to change FOV setting.")
	var camera_controller: CameraController = (players[0] as PlayerEntity).camera_controller
	camera_controller.refresh_sensitivity_from_settings()
