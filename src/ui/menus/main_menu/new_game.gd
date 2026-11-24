extends UIButton


func _button_ready() -> void:
	pass


func _button_pressed() -> void:
	var slot_index: int = SaveManager.get_latest_slot()
	var loaded: bool = (SaveManager.initialize_new_save(SaveManager.FIRST_MANUAL_SLOT)
		if slot_index == -1
		else SaveManager.load_from_slot(slot_index))

	if loaded:
		ApplicationStateManager.request_play_from_save()
