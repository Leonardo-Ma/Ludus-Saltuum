extends UIButton


func _button_ready() -> void:
	pass


func _button_pressed() -> void:
	if SaveManager.has_any_save():
		ApplicationStateManager.request_start_game()
		return

	SaveManager.initialize_new_save(SaveManager.FIRST_MANUAL_SLOT)
	ApplicationStateManager.request_play_from_save()
