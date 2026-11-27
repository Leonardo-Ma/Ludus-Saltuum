class_name ReturnCheckpointIndicator
extends TextureProgressBar

## Circular clock progress bar while holding return to checkpoint

var _tween: Tween
var _input: InputController


func bind_input(input: InputController) -> void:
	if is_instance_valid(_input):
		_input.return_hold_started.disconnect(_on_hold_started)
		_input.return_hold_cancelled.disconnect(_on_hold_cancelled)
	_on_hold_cancelled()
	_input = input
	if _input != null:
		_input.return_hold_started.connect(_on_hold_started)
		_input.return_hold_cancelled.connect(_on_hold_cancelled)


func _on_hold_started(duration: float) -> void:
	if _tween:
		_tween.kill()
	value = 0.0
	show()
	_tween = create_tween()
	_tween.tween_property(self, "value", 100.0, duration).set_trans(Tween.TRANS_LINEAR)
	_tween.tween_callback(hide)


func _on_hold_cancelled() -> void:
	if _tween:
		_tween.kill()
	hide()
