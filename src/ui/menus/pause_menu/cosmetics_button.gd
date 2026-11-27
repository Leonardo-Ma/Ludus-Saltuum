class_name PauseCosmeticsButton
extends UIButton

const OUTLINE_COLOR_DIM: Color = Color(1.0, 0.85, 0.3, 0.35)
const OUTLINE_COLOR_BRIGHT: Color = Color(1.0, 1.0, 0.85, 1.0)
const OUTLINE_COLOR_HIDDEN: Color = Color(1.0, 0.85, 0.3, 0.0)
const PULSE_HALF_PERIOD: float = 0.4
const FADE_OUT_DURATION: float = 0.2
## 6 * 2 * 0.4 + FADE_OUT_DURATION = 5 seconds
const PULSE_COUNT: int = 6

var _outline_style: StyleBoxFlat
var _tween: Tween
var _cosmetics: CosmeticsController

@onready var _outline: Panel = %HighlightOutline


func _button_ready() -> void:
	_outline_style = _outline.get_theme_stylebox(&"panel") as StyleBoxFlat
	ApplicationStateManager.gameplay_paused.connect(_on_gameplay_paused)
	ApplicationStateManager.gameplay_resumed.connect(_stop_outline)


func _button_pressed() -> void:
	_stop_outline()
	ApplicationStateManager.request_open_menu(ApplicationStateManager.GameState.COSMETICS_MENU)


func _on_gameplay_paused() -> void:
	if not is_instance_valid(_cosmetics) or not _cosmetics.consume_reminder():
		return

	_play_outline()


## Clears reminder animation when assigned player changes
func bind_cosmetics(cosmetics: CosmeticsController) -> void:
	_stop_outline()
	_cosmetics = cosmetics


func _play_outline() -> void:
	_stop_outline()
	_tween = create_tween()
	for _pulse: int in PULSE_COUNT:
		_tween.tween_property(_outline_style, "border_color", OUTLINE_COLOR_BRIGHT, PULSE_HALF_PERIOD)
		_tween.tween_property(_outline_style, "border_color", OUTLINE_COLOR_DIM, PULSE_HALF_PERIOD)
	_tween.tween_property(_outline_style, "border_color", OUTLINE_COLOR_HIDDEN, FADE_OUT_DURATION)


func _stop_outline() -> void:
	if _tween != null:
		_tween.kill()
	_outline_style.border_color = OUTLINE_COLOR_HIDDEN
