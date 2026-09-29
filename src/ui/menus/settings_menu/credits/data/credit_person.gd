## First-party contributor containing name and reusable project roles
class_name CreditPerson
extends Resource

@export var display_name: String
@export var roles: Array[CreditRole] = []
