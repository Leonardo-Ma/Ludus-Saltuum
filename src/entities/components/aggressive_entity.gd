@abstract class_name AggressiveEntity
extends CharacterBody3D

## Generic abstract class for entities that take damage and attack [br]
## Refer to subclass sandbox https://gameprogrammingpatterns.com/subclass-sandbox.html

signal melee_attacked
@warning_ignore("unused_signal")
signal magic_casted

@onready var collision_shape: CollisionShape3D = %CollisionShape3D

@onready var hitbox: Hitbox = %Hitbox
@onready var hurtbox: Hurtbox = %Hurtbox
@onready var status_manager: StatusManager = %StatusManager

@onready var health: HealthComponent = %HealthComponent
# TODO Find better way to implement this, other places use this reference from player
var attack: Attack:
	get:
		return attack_component.get_effective_attack() if attack_component else null
@onready var weapon_visual: WeaponVisual = %WeaponVisual
@onready var attack_component: AttackComponent = %AttackComponent

@onready var _lifecycle: EntityLifecycleController = %EntityLifecycleController
@onready var _damage_feedback: EntityDamageFeedback = %EntityDamageFeedback
@onready var _combat_audio: EntityCombatAudio = %EntityCombatAudio
@onready var _animation: AnimationController = %AnimationController


func _push_rigid_body(collision: KinematicCollision3D, push_force: float) -> void:
	var collider: Object = collision.get_collider()
	if collider is RigidBody3D:
		var body: RigidBody3D = collider
		var push_dir: Vector3 = -collision.get_normal()
		# Push down or sideways, never up
		if push_dir.y > 0.0:
			push_dir.y = 0.0
		if not push_dir.is_zero_approx():
			body.apply_central_impulse(push_dir.normalized() * push_force)


## Children should override _child_ready instead of this
func _ready() -> void:
	assert(collision_shape.shape, "CollisionShape missing in " + name)
	assert(hitbox and hitbox.animated_shape, "Melee hitbox incorrect for " + name)
	assert(hurtbox, "Hurtbox incorrect for " + name)
	assert(status_manager, "Status Manager missing for " + name)
	assert(weapon_visual, "WeaponVisual missing for " + name)

	assert(_lifecycle, "lifecycle missing for " + name)
	assert(_damage_feedback, "damage_feedback missing for " + name)
	assert(_combat_audio, "combat_audio missing for " + name)
	assert(_animation, "AnimationController missing for " + name)
	assert(attack_component, "AttackComponent missing for " + name)

	_lifecycle.initialize()
	_damage_feedback.initialize()
	_combat_audio.initialize()

	weapon_visual.weapon_replaced.connect(refresh_damage_feedback_meshes)

	_lifecycle.dying.connect(_on_dying)
	_lifecycle.death_completed.connect(_on_death_complete)
	_lifecycle.revived.connect(_on_revived)

	_child_ready()


## Virtual method for subclasses to override instead of _ready()
@abstract func _child_ready() -> void


## To Override [br]
## Async post-death behavior (e.g. respawn, scene transition) [br]
## Called when death sequence is finished
@abstract func _on_death_complete() -> void


## Hook for subclasses to react on death, before disable_entity() runs
func _on_dying() -> void:
	pass


## Hook for subclasses to react on revive
func _on_revived() -> void:
	pass


## Also used by save/load
func disable_entity() -> void:
	_lifecycle.disable()


func try_melee_attack() -> bool:
	if not can_process() or not _lifecycle.is_alive() or not attack_component.can_attack():
		return false
	var attack_used: Attack = attack_component.get_effective_attack()
	if not _animation.request_action(AnimKeys.MELEE, attack_used.rate):
		return false

	hitbox.arm(attack_used)
	attack_component.start_cooldown(attack_used.rate)
	melee_attacked.emit()
	return true


func interrupt_melee_attack() -> void:
	_animation.abort_action(AnimKeys.MELEE)


## Used on world reset/load
func revive() -> void:
	_lifecycle.revive()


## Call after meshes were swapped so damage overlay covers new meshes
func refresh_damage_feedback_meshes() -> void:
	_damage_feedback.refresh_meshes()


# NOTE Used in animation player
func play_attack_sound() -> void:
	_combat_audio.play_attack_sound()


func _create_timer(duration: float, callback: Callable) -> void:
	get_tree().create_timer(duration).timeout.connect(callback)
