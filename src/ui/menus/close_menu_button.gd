extends TextureButton

# TODO Change this variable to a global theme
const CLOSE_COLOR: Color = Color.RED


func _ready() -> void:
	modulate = CLOSE_COLOR
	pressed.connect(_on_pressed)


func _on_pressed() -> void:
	ApplicationStateManager.request_close_menu()
