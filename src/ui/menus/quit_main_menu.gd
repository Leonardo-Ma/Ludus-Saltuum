extends UITextureButton

const CLOSE_COLOR: Color = Color.RED


func _button_ready() -> void:
	modulate = CLOSE_COLOR


func _button_pressed() -> void:
	ApplicationStateManager.request_main_menu()
