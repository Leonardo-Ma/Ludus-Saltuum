# TODO Remake this garbage :(
class_name PlayerAnimationController
extends Node

## Entity animation controller [br]
## To be attached to AnimationTree [br]
## This acts as a signal listener from other nodes to change animation [br]

# TODO Improve these names and remove magic strings
const PARAM_MOVEMENT_BLEND_POSITION: String = "parameters/movement/blend_position"
const PARAM_STANCE_TRANSITION: String = "parameters/stance/transition_request"
const PARAM_CROUCH_MOVEMENT_BLEND_POSITION: String = "parameters/crouch_movement/blend_position"
const PARAM_IN_AIR_STATE_TRANSITION: String = "parameters/in_air_state/transition_request"
const PARAM_IN_AIR_STATE_CURRENT: String = "parameters/in_air_state/current_state"
const PARAM_IS_JUMPING_REQUEST: String = "parameters/is_jumping/request"
const PARAM_ATTACK_TRANSITION: String = "parameters/melee_attack/transition_request"
const PARAM_MELEE_ATTACK_TRANSITION: String = "parameters/melee_attack/transition_request"
const PARAM_ATTACK_REQUEST: String = "parameters/attack/request"
const PARAM_ATTACK_ACTIVE: String = "parameters/attack/active"
const PARAM_MAGIC_ATTACK_REQUEST: String = "parameters/magic_attack/request"
const PARAM_MAGIC_ATTACK_ACTIVE: String = "parameters/magic_attack/active"
const PARAM_IS_ALIVE_TRANSITION: String = "parameters/is_alive/transition_request"
const PARAM_DEATH_TRANSITION: String = "parameters/death/transition_request"
const PARAM_IS_DAMAGED_REQUEST: String = "parameters/is_damaged/request"
const PARAM_DAMAGED_TRANSITION: String = "parameters/damaged/transition_request"

const MELEE_ATTACK_ANIMATIONS: Array[String] = ["1h_slice_diagonal", "1h_slice_horizontal", "1h_stab"]
const DAMAGED_ANIMATIONS: Array[String] = ["hit_a", "hit_b"]
const DEATH_ANIMATIONS: Array[String] = ["death_a", "death_b"]

@onready var entity: AggressiveEntity = owner as AggressiveEntity
@onready var health: HealthComponent = %HealthComponent

var movement: MovementComponent


func initialize() -> void:
	if entity is PlayerEntity:
		var movement_controller: PlayerMovementComponent = entity.get_node("%PlayerMovementComponent")
		assert(movement_controller, "movement_controller missing for " + owner.name)
		#		movement_controller.move_stopped.connect(_on_move_stopped)
		movement_controller.movement_direction_changed.connect(_on_movement_direction_changed)
		movement_controller.jumped.connect(_on_jumped)
		movement_controller.in_air.connect(_on_in_air)
		movement_controller.landed.connect(_on_landed)
		movement_controller.crouch_toggled.connect(_on_crouch_toggled)
		movement_controller.movement_direction_changed.connect(_on_player_movement_direction_changed)
	elif entity is NPCEntity:
		var npc_movement_controller: NPCMovementController = entity.get_node("%NPCMovementController")
		assert(npc_movement_controller, "npc_movement_controller missing for " + owner.name)
		npc_movement_controller.movement_direction_changed.connect(_on_movement_direction_changed)
	else:
		assert(false, "Entity " + owner.name + " not supported but has animation controller")
	_validate_animation_parameters()

	entity.melee_attacked.connect(_on_melee_attack)
	entity.magic_casted.connect(_on_magic_casted)

	health.damaged.connect(_on_damaged)
	health.died.connect(_on_death)
	health.revived.connect(_on_revived)

# Only if multiple idle animations (Need to create new connection in tree)
#func _on_move_stopped() -> void:
#	set("parameters/moving/transition_request", "idle")


# BUG If player uses shift + movement, strafe animation gets stuck if: shift + a/d + w  then releasing w
# removed strafe left and right on animation tree movement
## Update BlendSpace2D position in animation tree
## X axis: left (-1) to right (1)
## Y axis: backward (-0.6 walk, -1.0 run) to forward (0.6 walk, 1.0 run)
## Direction vector already scaled by speed_factor in movement controller
func _on_movement_direction_changed(direction: Vector2, _speed_factor: float) -> void:
	set(PARAM_MOVEMENT_BLEND_POSITION, direction)


func _on_jumped() -> void:
	set(PARAM_IN_AIR_STATE_TRANSITION, "air")
	set(PARAM_IS_JUMPING_REQUEST, AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)


func _on_in_air() -> void:
	set(PARAM_IN_AIR_STATE_TRANSITION, "air")
	# TODO Consider input buffering, so if you attack when about to hit ground, it triggers attack
	_abort_attack()


func _on_landed() -> void:
	set(PARAM_IN_AIR_STATE_TRANSITION, "ground")


func _on_melee_attack() -> void:
	if get(PARAM_IN_AIR_STATE_CURRENT) != "ground" or get(PARAM_ATTACK_ACTIVE) == true:
		return

	set(PARAM_MELEE_ATTACK_TRANSITION, MELEE_ATTACK_ANIMATIONS.pick_random())

	set(PARAM_ATTACK_REQUEST, AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)


func _on_magic_casted() -> void:
	if get(PARAM_MAGIC_ATTACK_ACTIVE) == true:
		return

	set(PARAM_MAGIC_ATTACK_REQUEST, AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)


func _on_damaged(_attack: Attack) -> void:
	set(PARAM_IS_ALIVE_TRANSITION, "damaged")
	set(PARAM_DAMAGED_TRANSITION, DAMAGED_ANIMATIONS.pick_random())
	set(PARAM_IS_DAMAGED_REQUEST, AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)


func _on_death() -> void:
	set(PARAM_IS_ALIVE_TRANSITION, "dead")
	set(PARAM_DEATH_TRANSITION, DEATH_ANIMATIONS.pick_random())
	set(PARAM_IS_DAMAGED_REQUEST, AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)


func _on_revived() -> void:
	set(PARAM_IS_ALIVE_TRANSITION, "respawn")
	set(PARAM_IS_DAMAGED_REQUEST, AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)


func _abort_attack() -> void:
	set(PARAM_ATTACK_REQUEST, AnimationNodeOneShot.ONE_SHOT_REQUEST_ABORT)
	# The RESET reverts any animation based function or parameter to default state
	entity.animation_player.play("RESET")


func _on_player_movement_direction_changed(direction: Vector2, _speed_factor: float) -> void:
	set(PARAM_CROUCH_MOVEMENT_BLEND_POSITION, direction)


func _on_crouch_toggled(active: bool) -> void:
	set(PARAM_STANCE_TRANSITION, "crouching" if active else "standing")


# TODO Remake this garbage
func _validate_animation_parameters() -> void:
	var required_parameters: Array[String] = [
		PARAM_MOVEMENT_BLEND_POSITION,
		PARAM_IN_AIR_STATE_TRANSITION,
		PARAM_IS_JUMPING_REQUEST,
		PARAM_ATTACK_REQUEST,
		PARAM_MELEE_ATTACK_TRANSITION,
		PARAM_MAGIC_ATTACK_REQUEST,
		PARAM_MAGIC_ATTACK_ACTIVE,
		PARAM_IS_DAMAGED_REQUEST,
		PARAM_DEATH_TRANSITION,
		PARAM_DAMAGED_TRANSITION,
		PARAM_IS_ALIVE_TRANSITION,
	]

	if entity is PlayerEntity:
		required_parameters.append_array([PARAM_STANCE_TRANSITION, PARAM_CROUCH_MOVEMENT_BLEND_POSITION])

	#for param: String in required_parameters:
	#	assert(get(param), "Missing animation parameter: " + param + " in " + owner.name)
