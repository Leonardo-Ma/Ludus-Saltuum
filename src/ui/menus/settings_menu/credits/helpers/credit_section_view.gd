## Displays one ordered credits category and its entries
class_name CreditSectionView
extends VBoxContainer

@export var person_scene: PackedScene
@export var asset_scene: PackedScene

@onready var icon: TextureRect = %Icon
@onready var title_label: Label = %TitleLabel
@onready var people_container: VBoxContainer = %PeopleContainer
@onready var assets_container: VBoxContainer = %AssetsContainer


func setup(section: CreditSection) -> void:
	icon.texture = section.icon
	title_label.text = section.display_name

	people_container.visible = not section.people.is_empty()
	assets_container.visible = not section.assets.is_empty()

	for person: CreditPerson in section.people:
		var person_view: CreditPersonView = person_scene.instantiate()
		people_container.add_child(person_view)
		person_view.setup(person)

	for asset: CreditAsset in section.assets:
		var asset_view: CreditAssetView = asset_scene.instantiate()
		assets_container.add_child(asset_view)
		asset_view.setup(asset)
