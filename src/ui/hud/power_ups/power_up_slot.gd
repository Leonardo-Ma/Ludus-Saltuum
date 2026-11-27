class_name PowerUpSlot
extends HBoxContainer

## Animates one active status using timing supplied by status model

const FLASH_WINDOW: float = 3.0
const FLASH_HALF_PERIOD: float = 0.2
const FLASH_COLOR: Color = Color(1.5, 1.5, 0.5, 1.0)

var _cooldown_tween: Tween
var _flash_tween: Tween

@onready var _icon: TextureRect = %PowerUp
@onready var _cooldown: TextureProgressBar = %CooldownProgress


func display_status(icon: Texture2D, remaining_time: float, total_duration: float, infinite: bool) -> void:
	_stop_animation()
	_icon.texture = icon
	_cooldown.texture_progress = icon
	_cooldown.visible = not infinite
	show()

	if infinite:
		return

	var span: float = maxf(total_duration, remaining_time)
	var elapsed_fraction: float = 1.0 - remaining_time / span if span > 0.0 else 1.0
	_cooldown.value = lerpf(_cooldown.min_value, _cooldown.max_value, clampf(elapsed_fraction, 0.0, 1.0))
	if remaining_time <= 0.0:
		return

	_cooldown_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_STOP)
	_cooldown_tween.tween_property(_cooldown, "value", _cooldown.max_value, remaining_time)
	_flash_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_STOP)
	_flash_tween.tween_interval(maxf(remaining_time - FLASH_WINDOW, 0.0))
	_flash_tween.tween_callback(_start_flash)


func clear() -> void:
	_stop_animation()
	hide()


func _start_flash() -> void:
	_flash_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_STOP).set_loops()
	_flash_tween.tween_property(_icon, "modulate", FLASH_COLOR, FLASH_HALF_PERIOD)
	_flash_tween.tween_property(_icon, "modulate", Color.WHITE, FLASH_HALF_PERIOD)


func _stop_animation() -> void:
	if _cooldown_tween != null:
		_cooldown_tween.kill()
	if _flash_tween != null:
		_flash_tween.kill()
	_icon.modulate = Color.WHITE
