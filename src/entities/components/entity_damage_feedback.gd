# TODO Find a better name and a better way to present regeneration and damage
class_name EntityDamageFeedback
extends Node

## Hit flash and heal pulse through material overlay on all meshes of body

const DAMAGE_FLASH_COLOR: Color = Color(1.0, 1.0, 1.0, 0.5)
const DAMAGE_FLASH_DURATION: float = 0.2
const HEAL_FLASH_COLOR: Color = Color(0.3, 1.0, 0.3, 0.4)
const HEAL_FLASH_DURATION: float = 1.5

@onready var _entity: CharacterBody3D = owner as CharacterBody3D
@onready var _skeleton_3d: Skeleton3D = %Skeleton3D
@onready var _health: HealthComponent = %HealthComponent

var _material: StandardMaterial3D
var _tween: Tween
var _prev_health: int = 0


func initialize() -> void:
	assert(_entity, "Entity owner missing in " + name)
	assert(_skeleton_3d, "Make Skeleton3D unique name for " + _entity.name)
	assert(_health, "HealthComponent missing in " + _entity.name)

	_material = StandardMaterial3D.new()
	_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_material.albedo_color = Color(1.0, 1.0, 1.0, 0.0)

	refresh_meshes()

	_prev_health = _health.current_health
	_health.died.connect(_kill_tween)
	_health.damaged.connect(_on_damaged)
	_health.health_changed.connect(_on_health_changed)


func refresh_meshes() -> void:
	assert(_material, "Damage material not initialized in " + name)

	for node: MeshInstance3D in _skeleton_3d.find_children("*", "MeshInstance3D", true, false):
		node.material_overlay = _material


func _on_damaged(_attack: Attack) -> void:
	_kill_tween()

	_material.albedo_color = DAMAGE_FLASH_COLOR
	_tween = create_tween()
	_tween.tween_property(_material, "albedo_color:a", 0.0, DAMAGE_FLASH_DURATION).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func _on_health_changed(new_health: int) -> void:
	if new_health > _prev_health:
		_kill_tween()
		# Flash green on heal (pulse)
		_material.albedo_color = HEAL_FLASH_COLOR
		_tween = create_tween()
		_tween.tween_property(_material, "albedo_color:a", 0.0, HEAL_FLASH_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	_prev_health = new_health


func _kill_tween() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
