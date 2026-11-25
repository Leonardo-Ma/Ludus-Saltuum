@abstract class_name AnimationBridge
extends Node

## Forwards entity combat and life signals to AnimationController, subclasses wire locomotion

@onready var _controller: AnimationController = %AnimationController
@onready var _health: HealthComponent = %HealthComponent
@onready var _entity: AggressiveEntity = owner
@onready var _hitbox: Hitbox = %Hitbox


func _ready() -> void:
	assert(_entity, "AggressiveEntity owner missing in " + name)
	assert(_controller and _health and _hitbox, "Animation bridge dependencies missing in " + name)
	_health.damaged.connect(_on_damaged)
	_health.died.connect(_on_died)
	_health.revived.connect(_on_revived)
	_entity.magic_casted.connect(_on_magic_casted)
	_controller.action_finished.connect(_close_melee_window)
	_controller.action_interrupted.connect(_close_melee_window)
	_child_ready()


## Children override this instead of _ready()
@abstract func _child_ready() -> void


func _on_damaged(_attack: Attack) -> void:
	_controller.request_action(AnimKeys.HIT)


func _on_died() -> void:
	_controller.set_dead(true)


func _on_revived() -> void:
	_controller.set_dead(false)


func _on_magic_casted() -> void:
	_controller.request_action(AnimKeys.MAGIC)


func _close_melee_window(action_id: StringName) -> void:
	if action_id == AnimKeys.MELEE:
		_hitbox.close_attack_window()
