class_name EnvironmentFadeOverlay
extends CanvasLayer

## Covers a view change by displaying current camera transition progress

var _controller: EnvironmentTransitionController

@onready var _fade_rect: ColorRect = $FadeRect


func bind_transition(controller: EnvironmentTransitionController) -> void:
	if is_instance_valid(_controller):
		_controller.transition_coverage_changed.disconnect(_set_coverage)
	_controller = controller
	if _controller != null:
		_controller.transition_coverage_changed.connect(_set_coverage)
	_set_coverage(_controller.get_transition_coverage() if _controller != null else 0.0)


func _set_coverage(coverage: float) -> void:
	_fade_rect.modulate.a = coverage
