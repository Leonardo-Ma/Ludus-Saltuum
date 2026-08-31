extends UIButton


func _button_ready() -> void:
	if OS.has_feature("demo"):
		visible = false


func _button_pressed() -> void:
	ApplicationStateManager.request_achievements_menu()
