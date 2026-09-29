## Opens configured external credit URL when pressed
class_name CreditLinkButton
extends UIButton

@export var url: String


func _button_ready() -> void:
	pass


func _button_pressed() -> void:
	if url.is_empty():
		return

	OS.shell_open(url)
