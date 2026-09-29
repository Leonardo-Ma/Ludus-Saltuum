## Displays one credit role icon and name
class_name CreditRoleView
extends HBoxContainer

@onready var icon: TextureRect = %Icon
@onready var label: Label = %Label


func setup(role: CreditRole) -> void:
	icon.texture = role.icon
	label.text = role.display_name
