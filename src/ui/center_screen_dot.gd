extends ColorRect


func _ready() -> void:
	GameplayStateManager.gameplay_mode_changed.connect(_on_gameplay_mode_changed)


func _on_gameplay_mode_changed(new_mode: GameplayStateManager.GameplayMode, _previous_mode: GameplayStateManager.GameplayMode) -> void:
	if new_mode == GameplayStateManager.GameplayMode.RACING:
		visible = false
	else:
		visible = true
