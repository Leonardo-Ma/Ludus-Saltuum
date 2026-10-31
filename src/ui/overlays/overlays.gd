extends Control

@onready var screen_transition: Control = %ScreenTransition
@onready var fade_rect: ColorRect = %FadeRect

var _fade_tween: Tween


func _ready() -> void:
	fade_rect.modulate.a = 0.0
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

	screen_transition.visible = false

	ControlledEntityEvents.player_respawning.connect(_on_player_respawning)
	ControlledEntityEvents.player_finished_respawning.connect(_on_player_finished_respawning)


## Fade in and out effect, to solid color then back
func _on_player_respawning(_duration: float) -> void:
	screen_transition.visible = true
	_kill_fade_tween()

	_fade_tween = create_tween()
	_fade_tween.tween_property(fade_rect, "modulate:a", 1.0, 0.5).set_trans(Tween.TRANS_SINE)


func _on_player_finished_respawning() -> void:
	_kill_fade_tween()

	_fade_tween = create_tween()
	_fade_tween.tween_property(fade_rect, "modulate:a", 0.0, 0.5).set_trans(Tween.TRANS_SINE)

	await _fade_tween.finished
	screen_transition.visible = false


func _kill_fade_tween() -> void:
	if _fade_tween != null and _fade_tween.is_running():
		_fade_tween.kill()
