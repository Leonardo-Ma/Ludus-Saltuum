class_name EntityLifecycleController
extends Node

## Binds Health to entity lifetime: death sequence, disable and revive

signal dying
signal death_completed
signal revived

const DEATH_LINGER_DURATION: float = 2.0
const DEATH_SHRINK_DURATION: float = 1.5
const DEATH_END_SCALE: Vector3 = Vector3(0.001, 0.001, 0.001)

enum LifecycleState {
	ALIVE = 0,
	DYING = 1,
	DEAD = 2,
}

@onready var _entity: CharacterBody3D = owner as CharacterBody3D

@onready var _hitbox: Hitbox = %Hitbox
@onready var _hurtbox: Hurtbox = %Hurtbox
@onready var _collision_shape: CollisionShape3D = %CollisionShape3D

@onready var _health: HealthComponent = %HealthComponent

var _state: LifecycleState = LifecycleState.ALIVE
var _initial_scale: Vector3
var _death_tween: Tween


func initialize() -> void:
	assert(_entity, "Entity owner missing in " + name)
	assert(_health, "HealthComponent missing in " + _entity.name)

	_initial_scale = _entity.scale

	_health.died.connect(_on_died)


func disable() -> void:
	_hitbox.set_deferred("monitoring", false)
	_hitbox.set_deferred("monitorable", false)
	_hurtbox.set_deferred("monitoring", false)
	_hurtbox.set_deferred("monitorable", false)
	_collision_shape.set_deferred("disabled", true)
	_entity.set_physics_process(false)


func revive() -> void:
	assert(_state != LifecycleState.DYING, "Cannot revive during death sequence in " + name)

	if _death_tween and _death_tween.is_valid():
		_death_tween.kill()

	_state = LifecycleState.ALIVE
	_health.reset()
	_entity.scale = _initial_scale
	_entity.visible = true
	_collision_shape.set_deferred("disabled", false)
	_entity.set_physics_process(true)
	_hitbox.set_deferred("monitoring", true)
	_hitbox.set_deferred("monitorable", true)
	_hurtbox.set_deferred("monitoring", true)
	_hurtbox.set_deferred("monitorable", true)
	revived.emit()


func _on_died() -> void:
	if _state != LifecycleState.ALIVE:
		return

	_state = LifecycleState.DYING
	dying.emit()
	disable()
	await _play_death_animation()

	if not is_inside_tree() or _state != LifecycleState.DYING:
		return

	_state = LifecycleState.DEAD
	death_completed.emit()


func _play_death_animation() -> void:
	_death_tween = create_tween()
	_death_tween.tween_interval(DEATH_LINGER_DURATION)
	_death_tween.tween_property(_entity, "scale", DEATH_END_SCALE, DEATH_SHRINK_DURATION).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	await _death_tween.finished
