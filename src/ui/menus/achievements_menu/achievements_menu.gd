## Row count and order are data-driven, so instancing happens in code
class_name AchievementsMenu
extends MenuScreen

@export var _row_scene: PackedScene
@onready var _rows_container: VBoxContainer = %RowsContainer


func _ready() -> void:
	assert(_row_scene != null, "AchievementsMenu: _row_scene not assigned in " + name)
	visibility_changed.connect(_on_visibility_changed)
	Achievements.achievement_unlocked.connect(_on_achievement_unlocked)
	_populate()


func _populate() -> void:
	for child: Node in _rows_container.get_children():
		_rows_container.remove_child(child)
		child.queue_free()
	for id: AchievementDefinition.Id in Achievements.get_sorted_ids():
		var row: AchievementRow = _row_scene.instantiate() as AchievementRow
		_rows_container.add_child(row)
		row.setup(id, Achievements.get_display_name(id), Achievements.get_description(id))


func _on_visibility_changed() -> void:
	if visible:
		_populate()


func _on_achievement_unlocked(_id: AchievementDefinition.Id) -> void:
	if visible:
		_populate()
