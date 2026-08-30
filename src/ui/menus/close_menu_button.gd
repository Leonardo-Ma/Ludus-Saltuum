extends UITextureButton

# TODO Change this variable to a global theme
const CLOSE_COLOR: Color = Color.RED


func _button_ready() -> void:
	modulate = CLOSE_COLOR


func _button_pressed() -> void:
	ApplicationStateManager.request_close_menu()
