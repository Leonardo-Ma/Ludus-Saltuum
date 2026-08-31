## Base texture button for animation, sfx and more
@abstract class_name UIButton
extends Button

const POP_SOUNDS: Array[AudioStream] = [
	preload("uid://bmmjv51rywjed"),  # pop_1.wav
	preload("uid://bs5ws2by636gj"),  # pop_2.wav
	preload("uid://51tu1dqta8wv"),  # pop_3.wav
	preload("uid://dyr0xhho2e7pv"),  # pop_4.wav
]

const HOVER_SOUND: AudioStream = preload("uid://cxb6ockccyuf0")  # switch1.wav

var _original_modulate: Color
var _hover_tween: Tween


func _ready() -> void:
	_original_modulate = modulate

	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	pressed.connect(_on_pressed)

	_button_ready()


func _on_pressed() -> void:
	(
		SoundManager
		. play_sound(
			POP_SOUNDS.pick_random(),
			SoundManager.SoundCategory.UI,
		)
	)

	_button_pressed()


## Function to override instead of _ready
@abstract func _button_ready() -> void

## Function to override instead of _on_pressed
@abstract func _button_pressed() -> void


func _on_mouse_entered() -> void:
	if disabled:
		return
	(
		SoundManager
		. play_sound(
			HOVER_SOUND,
			SoundManager.SoundCategory.UI,
		)
	)

	pivot_offset = size / 2.0

	if _hover_tween:
		_hover_tween.kill()

	_hover_tween = create_tween()
	(
		_hover_tween
		. tween_property(
			self,
			"scale",
			Vector2(1.05, 1.05),
			0.1,
		)
		. set_trans(Tween.TRANS_SINE)
		. set_ease(Tween.EASE_OUT)
	)
	(
		_hover_tween
		. parallel()
		. tween_property(
			self,
			"modulate",
			modulate,
			0.1,
		)
	)


func _on_mouse_exited() -> void:
	if disabled:
		return
	if _hover_tween:
		_hover_tween.kill()

	_hover_tween = create_tween()
	(
		_hover_tween
		. tween_property(
			self,
			"scale",
			Vector2.ONE,
			0.1,
		)
		. set_trans(Tween.TRANS_SINE)
		. set_ease(Tween.EASE_OUT)
	)
	(
		_hover_tween
		. parallel()
		. tween_property(
			self,
			"modulate",
			modulate,
			0.1,
		)
	)
