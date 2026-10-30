extends UIButton


func _button_ready() -> void:
	pass


func _button_pressed() -> void:
	if not SaveManager.has_any_save():
		SaveManager.initialize_new_save(SaveManager.FIRST_MANUAL_SLOT)
	else:
		SaveManager.load_from_slot(SaveManager.get_latest_slot())

	ApplicationStateManager.request_play_from_save()
