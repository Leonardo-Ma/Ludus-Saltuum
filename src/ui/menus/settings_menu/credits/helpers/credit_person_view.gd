## Displays one first-party contributor and their project roles
class_name CreditPersonView
extends VBoxContainer

@export var role_scene: PackedScene

@onready var name_label: Label = %NameLabel
@onready var roles_container: HBoxContainer = %RolesContainer


func setup(person: CreditPerson) -> void:
	name_label.text = person.display_name

	for role: CreditRole in person.roles:
		var role_view: CreditRoleView = role_scene.instantiate()
		roles_container.add_child(role_view)
		role_view.setup(role)
