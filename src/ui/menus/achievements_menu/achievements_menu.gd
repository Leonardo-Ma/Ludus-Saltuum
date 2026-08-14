## Row count and order are data-driven, so instancing happens in code
class_name AchievementsMenu
extends Control

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
	for key: StringName in Achievements.get_sorted_keys():
		var row: AchievementRow = _row_scene.instantiate() as AchievementRow
		_rows_container.add_child(row)
		row.setup(key, Achievements.get_display_name(key), Achievements.get_description(key))


func _on_visibility_changed() -> void:
	if visible:
		_populate()


func _on_achievement_unlocked(_key: StringName) -> void:
	if visible:
		_populate()
