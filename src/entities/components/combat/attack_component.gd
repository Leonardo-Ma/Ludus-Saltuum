# TODO BUG Find better way to implement this, I can't remove existing attack resource because
# it's already properly used for hazard and other scenarios, but I can't it to a node because it's a resource
# and direct reference in class seems wrong
class_name AttackComponent
extends Node

## Component for managing entity attack configuration and execution

@export var attack: Attack

var _effective_attack: Attack = null
var _cooldown_timer: SceneTreeTimer = null


func _ready() -> void:
	assert(attack and attack.damage > 0, "Attack not properly configured for " + owner.name)
	_effective_attack = attack


## Attack with modifiers applied, what hurtboxes receive
func get_effective_attack() -> Attack:
	return _effective_attack


## Runtime scaling, [member attack] resource stays untouched. Speed divides rate
func set_multipliers(damage_multiplier: float, attack_speed_multiplier: float) -> void:
	assert(damage_multiplier > 0.0 and attack_speed_multiplier > 0.0, "Invalid attack multipliers in " + owner.name)
	_effective_attack = attack.duplicate() as Attack
	_effective_attack.damage = maxi(1, roundi(attack.damage * damage_multiplier))
	_effective_attack.rate = attack.rate / attack_speed_multiplier


func can_attack() -> bool:
	return _cooldown_timer == null or _cooldown_timer.time_left <= 0.0


func start_cooldown() -> void:
	_cooldown_timer = get_tree().create_timer(_effective_attack.rate, false)
