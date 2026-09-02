extends Control

@onready var screen_transition: Control = %ScreenTransition
@onready var fade_rect: ColorRect = %FadeRect


func _ready() -> void:
	fade_rect.modulate.a = 0.0
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

	ControlledEntityEvents.player_respawning.connect(_on_player_respawning)


## Fade in and out effect, to solid color then back
func _on_player_respawning(duration: float) -> void:
	screen_transition.visible = true
	var tween: Tween = create_tween()
	tween.tween_property(fade_rect, "modulate:a", 1.0, duration / 2.0).set_trans(Tween.TRANS_SINE)
	tween.tween_property(fade_rect, "modulate:a", 0.0, duration / 2.0).set_trans(Tween.TRANS_SINE)
	# TODO Check if this impacts performance (maybe use multithread?)
	await tween.finished
	screen_transition.visible = false
