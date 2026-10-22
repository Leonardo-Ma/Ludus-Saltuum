## To be instantiated for each passed icon parameter
class_name ConfirmationIcon
extends TextureRect

@export var icon_size: Vector2 = Vector2(150.0, 150.0)


func _ready() -> void:
	custom_minimum_size = icon_size
