class_name PlayerCombatController
extends Node

## Routes player input and health events to combat reactions

var _player: PlayerEntity

@onready var _animation: AnimationController = %AnimationController
@onready var _jump_chop_shape: CollisionShape3D = %JumpChopShape


func _ready() -> void:
	_player = owner
	assert(_player, "PlayerEntity owner missing for " + name)
	assert(_animation and _jump_chop_shape, "Animation controller or jump chop shape missing in " + name)
	_animation.action_finished.connect(_on_action_ended)
	_animation.action_interrupted.connect(_on_action_ended)
	_player.ready.connect(_initialize, CONNECT_ONE_SHOT)


## Opens or closes jump chop's collision during its swing
func set_jump_chop_window_enabled(enabled: bool) -> void:
	_jump_chop_shape.set_deferred(&"disabled", not enabled or _player.hitbox.attack == null)


func _initialize() -> void:
	# Receives from input controller, routes accepted attacks through animation controller
	_player.input_controller.attack_pressed.connect(_on_attack_pressed)

	_player.health.damaged.connect(_on_damaged_vibration)
	_player.health.died.connect(_player.player_movement_controller.disable_movement.bind(INF))


func _on_action_ended(action_id: StringName) -> void:
	if action_id == AnimKeys.MELEE:
		set_jump_chop_window_enabled(false)


func _on_damaged_vibration(_attack: Attack) -> void:
	# TODO Change the gamepad index to the current player gamepad?
	Input.start_joy_vibration(0, 0.5, 0.5, 0.7)


func _on_attack_pressed() -> void:
	_player.try_melee_attack()
