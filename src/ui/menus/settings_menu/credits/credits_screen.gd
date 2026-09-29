## Presents ordered credits data inside scrollable predefined UI scenes
class_name CreditsScreen
extends Control

@export var credits: CreditsData
@export var section_scene: PackedScene

@onready var sections_container: VBoxContainer = %SectionsContainer


func _ready() -> void:
	_populate()


func _populate() -> void:
	for section: CreditSection in credits.sections:
		var section_view: CreditSectionView = section_scene.instantiate()
		sections_container.add_child(section_view)
		section_view.setup(section)
