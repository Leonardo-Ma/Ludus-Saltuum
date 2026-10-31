# TODO Refactor this to a generic close menu button that pops the stack and reuse for settings menu
extends UIButton


func _button_ready() -> void:
	pass


func _button_pressed() -> void:
	ApplicationStateManager.request_close_cosmetics()
