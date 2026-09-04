extends ColorRect


func _ready() -> void:
	GameplayStateManager.gameplay_mode_changed.connect(_on_gameplay_mode_changed)


# TODO Check better approach than ignores
@warning_ignore("unused_parameter") # gdlint-ignore-next-line unused-argument
func _on_gameplay_mode_changed(new_mode: GameplayStateManager.GameplayMode, previous_mode: GameplayStateManager.GameplayMode) -> void:
	print(GameplayStateManager.GameplayMode.find_key(new_mode))
	if new_mode == GameplayStateManager.GameplayMode.RACING:
		visible = false
	else:
		visible = true
