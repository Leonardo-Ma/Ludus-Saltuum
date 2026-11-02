## Handles player score and applies a visual animation
extends HBoxContainer

var _current_score: int = 0

@onready var _score_label: Label = %ScoreCounter
@onready var _score_icon: TextureRect = %ScoreIcon


func _ready() -> void:
	ControlledEntityEvents.player_finished_spawning.connect(_on_player_finished_spawning)


func _on_player_finished_spawning(player: Node3D) -> void:
	var _economy_controller: EconomyController = player.economy_controller

	_current_score = _economy_controller.score

	_economy_controller.score_changed.connect(_on_score_changed)

	_update_ui()


func _on_score_changed(new_score: int) -> void:
	var score_diff: int = new_score - _current_score
	_current_score = new_score
	_update_ui()

	var target_color: Color = Color.WHITE
	if score_diff > 0:
		target_color = Color.GREEN
	elif score_diff < 0:
		target_color = Color.RED

	_play_score_animation(target_color)


func _update_ui() -> void:
	_score_label.text = str(_current_score)


func _play_score_animation(target_color: Color) -> void:
	var tween: Tween = create_tween().set_parallel(true)

	if _score_label:
		_score_label.pivot_offset = _score_label.size / 2.0
		_score_label.modulate = target_color
		tween.tween_property(_score_label, "modulate", Color.WHITE, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.tween_property(_score_label, "scale", Vector2(1.5, 1.5), 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(_score_label, "scale", Vector2.ONE, 0.2).set_delay(0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	if _score_icon:
		_score_icon.pivot_offset = _score_icon.size / 2.0
		tween.tween_property(_score_icon, "rotation", deg_to_rad(15), 0.05).set_trans(Tween.TRANS_SINE)
		tween.tween_property(_score_icon, "rotation", deg_to_rad(-15), 0.1).set_delay(0.05).set_trans(Tween.TRANS_SINE)
		tween.tween_property(_score_icon, "rotation", 0.0, 0.05).set_delay(0.15).set_trans(Tween.TRANS_SINE)
