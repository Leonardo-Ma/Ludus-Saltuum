## Handles player gold and applies a visual animation
extends HBoxContainer

var _current_gold: int = 0
var _economy_controller: EconomyController

@onready var _gold_label: Label = %GoldCounter as Label
@onready var _gold_icon: TextureRect = %GoldIcon as TextureRect


func setup(economy_controller: EconomyController) -> void:
	_economy_controller = economy_controller

	_current_gold = _economy_controller.gold

	if not _economy_controller.gold_changed.is_connected(_on_gold_changed):
		_economy_controller.gold_changed.connect(_on_gold_changed)

	_update_ui(_current_gold)


func _on_gold_changed(new_gold: int) -> void:
	var gold_diff: int = new_gold - _current_gold
	_current_gold = new_gold
	_update_ui(new_gold)

	var target_color: Color = Color.WHITE
	if gold_diff > 0:
		target_color = Color.GREEN
	elif gold_diff < 0:
		target_color = Color.RED

	_play_gold_animation(target_color)


func _update_ui(gold: int) -> void:
	if _gold_label:
		_gold_label.text = str(gold)


func _play_gold_animation(target_color: Color) -> void:
	var tween: Tween = create_tween().set_parallel(true)

	if _gold_label:
		_gold_label.pivot_offset = _gold_label.size / 2.0
		_gold_label.modulate = target_color
		tween.tween_property(_gold_label, "modulate", Color.WHITE, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.tween_property(_gold_label, "scale", Vector2(1.5, 1.5), 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(_gold_label, "scale", Vector2.ONE, 0.2).set_delay(0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	if _gold_icon:
		_gold_icon.pivot_offset = _gold_icon.size / 2.0
		tween.tween_property(_gold_icon, "rotation", deg_to_rad(15), 0.05).set_trans(Tween.TRANS_SINE)
		tween.tween_property(_gold_icon, "rotation", deg_to_rad(-15), 0.1).set_delay(0.05).set_trans(Tween.TRANS_SINE)
		tween.tween_property(_gold_icon, "rotation", 0.0, 0.05).set_delay(0.15).set_trans(Tween.TRANS_SINE)
