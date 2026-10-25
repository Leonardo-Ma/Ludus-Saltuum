class_name EnvironmentTransitionController
extends Node

## Manages player environment changes with fade transition [br]
## Example: For cave darkness / outer space background

@export_range(0.0, 5.0, 0.05, "suffix:s") var fade_duration: float = 0.3

var _default_environment: Environment
var _active_zones: Array[Area3D] = []
var _transition_id: int = 0
var _fade_overlay: ColorRect

@onready var _camera: Camera3D = %Camera3D


func _ready() -> void:
	var player: PlayerEntity = owner
	assert(player != null, "EnvironmentTransitionController must be a child of player")

	_default_environment = _camera.environment
	_create_fade_overlay()


func _create_fade_overlay() -> void:
	var overlay_layer: CanvasLayer = CanvasLayer.new()
	overlay_layer.name = "EnvironmentFadeLayer"
	overlay_layer.layer = 100
	add_child(overlay_layer)

	_fade_overlay = ColorRect.new()
	_fade_overlay.name = "EnvironmentFadeOverlay"
	_fade_overlay.color = Color.BLACK
	_fade_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fade_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade_overlay.modulate.a = 0.0
	overlay_layer.add_child(_fade_overlay)


## Activates a zone and transitions to its environment.
func enter_zone(zone: Area3D, target_environment: Environment) -> void:
	assert(zone != null, "Environment zone is missing for " + name)
	assert(target_environment != null, "Target Environment is missing for " + zone.name)

	_active_zones.erase(zone)
	_active_zones.append(zone)
	await _transition_to(target_environment)


## Removes a zone and restores the previous active zone or default environment.
func exit_zone(zone: Area3D) -> void:
	_active_zones.erase(zone)

	var target_environment: Environment = _default_environment
	if not _active_zones.is_empty():
		var active_zone: Area3D = _active_zones.back()
		var zone_script: EnvironmentZone3D = active_zone as EnvironmentZone3D
		if zone_script != null:
			target_environment = zone_script.target_environment

	await _transition_to(target_environment)


func _transition_to(target_environment: Environment) -> void:
	if _camera.environment == target_environment:
		return

	_transition_id += 1
	var current_transition_id: int = _transition_id

	if fade_duration > 0.0:
		var fade_out: Tween = create_tween()
		fade_out.tween_property(_fade_overlay, "modulate:a", 1.0, fade_duration)
		await fade_out.finished

	if current_transition_id != _transition_id:
		return

	_camera.environment = target_environment

	if fade_duration > 0.0:
		var fade_in: Tween = create_tween()
		fade_in.tween_property(_fade_overlay, "modulate:a", 0.0, fade_duration)
	else:
		_fade_overlay.modulate.a = 0.0
