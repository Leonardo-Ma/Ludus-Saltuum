## Non-blocking toast on achievement unlock, queues consecutive unlocks
class_name AchievementToast
extends PanelContainer

const FADE_DURATION: float = 0.4
const VISIBLE_DURATION: float = 3.0

var _queue: Array[StringName] = []
var _is_showing: bool = false

@onready var _icon: TextureRect = %AchievementIcon
@onready var _name_label: Label = %NameLabel
@onready var _description_label: Label = %DescriptionLabel


func _ready() -> void:
	assert(_icon != null, "icon missing for " + name)
	assert(_name_label != null, "name_label missing for " + name)
	assert(_description_label != null, "description_label missing for " + name)

	hide()
	Achievements.achievement_unlocked.connect(_on_achievement_unlocked)


func _on_achievement_unlocked(key: StringName) -> void:
	_queue.push_back(key)
	if not _is_showing:
		_show_next()


func _show_next() -> void:
	if _queue.is_empty():
		_is_showing = false
		return

	_is_showing = true
	var key: StringName = _queue.pop_front()
	_name_label.text = Achievements.get_display_name(key)
	_description_label.text = Achievements.get_description(key)
	_icon.texture = Achievements.get_icon(key, true)

	modulate.a = 0.0
	show()

	var tween: Tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, FADE_DURATION)
	tween.tween_interval(VISIBLE_DURATION)
	tween.tween_property(self, "modulate:a", 0.0, FADE_DURATION)
	tween.tween_callback(_on_toast_finished)


func _on_toast_finished() -> void:
	hide()
	_show_next()
