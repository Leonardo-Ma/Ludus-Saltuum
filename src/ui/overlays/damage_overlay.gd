class_name DamageOverlay
extends ColorRect

## Flashes red when controlled player takes a hit

const FLASH_DURATION: float = 1.0
const FLASH_INTENSITY: float = 0.15

var _health: HealthComponent
var _tween: Tween


func bind_health(health: HealthComponent) -> void:
	if is_instance_valid(_health):
		_health.damaged.disconnect(_on_damaged)
	if _tween != null:
		_tween.kill()
	hide()
	_health = health
	if _health != null:
		_health.damaged.connect(_on_damaged)


func _on_damaged(_attack: Attack) -> void:
	if material is not ShaderMaterial:
		return
	if _tween != null:
		_tween.kill()

	var shader_material: ShaderMaterial = material
	shader_material.set_shader_parameter(&"intensity", FLASH_INTENSITY)
	show()
	_tween = create_tween()
	_tween.tween_property(shader_material, ^"shader_parameter/intensity", 0.0, FLASH_DURATION)
	_tween.tween_callback(hide)
