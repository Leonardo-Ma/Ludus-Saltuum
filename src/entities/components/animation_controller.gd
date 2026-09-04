#######################################
## Entity animation controller
## To be attached to AnimationTree
## This acts as a signal listener from other nodes to change animation
#######################################
extends Node

const PARAM_MOVEMENT_BLEND_POSITION: String = "parameters/movement/blend_position"
const PARAM_IN_AIR_STATE_TRANSITION: String = "parameters/in_air_state/transition_request"
const PARAM_IN_AIR_STATE_CURRENT: String = "parameters/in_air_state/current_state"
const PARAM_IS_JUMPING_REQUEST: String = "parameters/is_jumping/request"
const PARAM_ATTACK_TRANSITION: String = "parameters/attack_transition/transition_request"
const PARAM_ATTACK_REQUEST: String = "parameters/attack/request"
const PARAM_ATTACK_ACTIVE: String = "parameters/attack/active"
const PARAM_IS_ALIVE_TRANSITION: String = "parameters/is_alive/transition_request"
const PARAM_IS_DAMAGED_REQUEST: String = "parameters/is_damaged/request"

@onready var entity: CharacterBody3D = owner
@onready var health: Health = entity.health


func _ready() -> void:
	if entity is PlayerEntity:
		var movement_controller: MovementController = $%MovementController
		assert(movement_controller, "movement_controller missing for " + owner.name)
#		movement_controller.move_stopped.connect(_on_move_stopped)
		movement_controller.movement_direction_changed.connect(_on_movement_direction_changed)
		movement_controller.jumped.connect(_on_jumped)
		movement_controller.in_air.connect(_on_in_air)
		movement_controller.landed.connect(_on_landed)
#		magic_controller.casted.connect(_on_magic_casted)
	elif entity is AggressiveEntity:
		var navigation_controller: NavigationController = $%NavigationController
		assert(navigation_controller, "navigation_controller missing for " + owner.name)
		navigation_controller.movement_direction_changed.connect(_on_movement_direction_changed)
	else:
		assert(false, "Entity " + owner.name + "not supported but has animation controller")
	_validate_animation_parameters()
	entity.melee_attacked.connect(_on_melee_attack)
	health.damaged.connect(_on_damaged)
	health.died.connect(_on_death)
	#health.revived.connect(_on_revived)

# Only if multiple idle animations (Need to create new connection in tree)
#func _on_move_stopped() -> void:
#	self.set("parameters/moving/transition_request", "idle")


# BUG If player uses shift + movement, strafe animation gets stuck if: shift + a/d + w  then releasing w
# removed strafe left and right on animation tree movement
## Update BlendSpace2D position in animation tree
## X axis: left (-1) to right (1)
## Y axis: backward (-0.6 walk, -1.0 run) to forward (0.6 walk, 1.0 run)
## The direction vector is already scaled by speed_factor in the movement controller
func _on_movement_direction_changed(direction: Vector2, _speed_factor: float) -> void:
	self.set(PARAM_MOVEMENT_BLEND_POSITION, direction)


func _on_jumped() -> void:
	self.set(PARAM_IN_AIR_STATE_TRANSITION, "air")
	self.set(PARAM_IS_JUMPING_REQUEST, AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)


func _on_in_air() -> void:
	self.set(PARAM_IN_AIR_STATE_TRANSITION, "air")
	# TODO Consider input buffering, so if you attack when about to hit ground, it triggers attack
	_abort_attack()


func _on_landed() -> void:
	self.set(PARAM_IN_AIR_STATE_TRANSITION, "ground")


func _on_melee_attack() -> void:
	if self.get(PARAM_IN_AIR_STATE_CURRENT) != "ground" or self.get(PARAM_ATTACK_ACTIVE) == true:
		return
	self.set(PARAM_ATTACK_TRANSITION, "melee_attack")
	self.set(PARAM_ATTACK_REQUEST, AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)

#func _on_magic_casted() -> void:
#	self.set(PARAM_ATTACK_TRANSITION, "magic_attack")
#	self.set(PARAM_ATTACK_REQUEST, AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)


func _on_damaged(_attack: Attack) -> void:
	self.set(PARAM_IS_ALIVE_TRANSITION, "damaged")
	self.set(PARAM_IS_DAMAGED_REQUEST, AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)


func _on_death() -> void:
	self.set(PARAM_IS_ALIVE_TRANSITION, "dead")

# TODO Add new revive animation and state
#func _on_revived() -> void:
#	self.set(PARAM_IS_ALIVE_TRANSITION, "alive")


func _abort_attack() -> void:
	self.set(PARAM_ATTACK_REQUEST, AnimationNodeOneShot.ONE_SHOT_REQUEST_ABORT)
	# The RESET reverts any animation based function or parameter to default state
	entity.get_node("%AnimationPlayer").play("RESET")


func _validate_animation_parameters() -> void:
	var required_parameters: Array[String] = [
		#"parameters/moving/transition_request",
		PARAM_MOVEMENT_BLEND_POSITION,
		PARAM_IN_AIR_STATE_TRANSITION,
		PARAM_IS_JUMPING_REQUEST,
		PARAM_ATTACK_REQUEST,
		PARAM_IS_DAMAGED_REQUEST,
		PARAM_IS_ALIVE_TRANSITION,
	]

	for param: String in required_parameters:
		assert(self.get(param) != null, "Missing animation parameter: " + param + " in " + owner.name)
