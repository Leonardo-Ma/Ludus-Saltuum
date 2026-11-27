class_name EnvironmentTransitionController
extends Node

## Manages player environment changes with fade transition [br]
## Example: For cave darkness / outer space background

signal transition_coverage_changed(coverage: float)

@export_range(0.0, 5.0, 0.05, "suffix:s") var transition_duration: float = 0.3

var _default_environment: Environment
var _active_zones: Array[Area3D] = []
var _transition_coverage: float = 0.0
var _transition_tween: Tween

@onready var _camera: Camera3D = %Camera3D


func _ready() -> void:
	var player: PlayerEntity = owner
	assert(player != null, "Player owner missing in " + name)

	_default_environment = _camera.environment


## Returns normalized coverage, with camera switching at full coverage
func get_transition_coverage() -> float:
	return _transition_coverage


## Activates a zone and transitions to its environment.
func enter_zone(zone: Area3D, target_environment: Environment) -> void:
	assert(zone != null, "Environment zone is missing for " + name)
	assert(target_environment != null, "Target Environment missing for %s in %s" % [zone.name, name])

	_active_zones.erase(zone)
	_active_zones.append(zone)
	_transition_to(target_environment)


## Removes a zone and restores the previous active zone or default environment.
func exit_zone(zone: Area3D) -> void:
	_active_zones.erase(zone)

	var target_environment: Environment = _default_environment
	if not _active_zones.is_empty():
		var active_zone: Area3D = _active_zones.back()
		if active_zone is EnvironmentZone3D:
			var zone_script: EnvironmentZone3D = active_zone
			target_environment = zone_script.target_environment

	_transition_to(target_environment)


func _transition_to(target_environment: Environment) -> void:
	if _transition_tween != null and _transition_tween.is_valid():
		_transition_tween.kill()
	if transition_duration <= 0.0:
		_set_environment(target_environment)
		_set_transition_coverage(0.0)
		return

	var changes_environment: bool = _camera.environment != target_environment
	if not changes_environment and _transition_coverage == 0.0:
		return

	_transition_tween = create_tween()
	if changes_environment:
		_transition_tween.tween_method(_set_transition_coverage, _transition_coverage, 1.0, transition_duration)
		_transition_tween.tween_callback(_set_environment.bind(target_environment))
	var reveal_from: float = 1.0 if changes_environment else _transition_coverage
	_transition_tween.tween_method(_set_transition_coverage, reveal_from, 0.0, transition_duration)


func _set_environment(environment: Environment) -> void:
	_camera.environment = environment


func _set_transition_coverage(coverage: float) -> void:
	_transition_coverage = coverage
	transition_coverage_changed.emit(coverage)
