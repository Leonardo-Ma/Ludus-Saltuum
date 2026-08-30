extends UITextureButton

const SHUT_DOWN_SOUND: AudioStream = preload("uid://yvujl2l3onjt")  # synth_shut_down.wav
const SHUTDOWN_DELAY: float = 0.4
const CLOSE_COLOR: Color = Color.RED


func _button_ready() -> void:
	modulate = CLOSE_COLOR


func _button_pressed() -> void:
	SoundManager.play_sound(SHUT_DOWN_SOUND, SoundManager.SoundCategory.UI)
	await get_tree().create_timer(SHUTDOWN_DELAY).timeout
	ApplicationStateManager.request_quit()
