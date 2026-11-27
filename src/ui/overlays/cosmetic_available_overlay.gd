class_name CosmeticAvailableOverlay
extends Control

## Toast shown when player can afford an unowned cosmetic

const TOTAL_DURATION: float = 5.0
const FADE_DURATION: float = 0.4

var _tween: Tween
var _cosmetics: CosmeticsController


func _ready() -> void:
	hide()


func bind_cosmetics(cosmetics: CosmeticsController) -> void:
	if is_instance_valid(_cosmetics):
		_cosmetics.affordable_cosmetic_reminded.disconnect(_on_reminder)
	if _tween != null:
		_tween.kill()
	hide()
	_cosmetics = cosmetics
	if _cosmetics != null:
		_cosmetics.affordable_cosmetic_reminded.connect(_on_reminder)


func _on_reminder() -> void:
	if _tween != null:
		_tween.kill()

	modulate.a = 0.0
	show()
	_tween = create_tween()
	_tween.tween_property(self, "modulate:a", 1.0, FADE_DURATION)
	_tween.tween_interval(TOTAL_DURATION - 2.0 * FADE_DURATION)
	_tween.tween_property(self, "modulate:a", 0.0, FADE_DURATION)
	_tween.tween_callback(hide)
