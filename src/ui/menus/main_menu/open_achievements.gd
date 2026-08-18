extends TextureButton


func _ready() -> void:
	if OS.has_feature("demo"):
		visible = false

	pressed.connect(_on_pressed)


func _on_pressed() -> void:
	ApplicationStateManager.request_achievements_menu()
