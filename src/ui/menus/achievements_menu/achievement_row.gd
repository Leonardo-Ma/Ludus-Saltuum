## Single achievement row, populated at runtime via setup()
class_name AchievementRow
extends MarginContainer

var _id: AchievementDefinition.Id = AchievementDefinition.Id.UNDEFINED

@onready var _name_label: Label = %NameLabel
@onready var _description_label: Label = %DescriptionLabel
@onready var _icon: TextureRect = %Icon


func setup(id: AchievementDefinition.Id, display_name: String, description: String) -> void:
	_id = id
	_name_label.text = display_name
	_description_label.text = description
	refresh()


func refresh() -> void:
	var unlocked: bool = Achievements.is_unlocked(_id)
	_icon.texture = Achievements.get_icon(_id, unlocked)
