class_name PlayerCombatController
extends Node

## Routes player input and health events to combat reactions

var _player: PlayerEntity


func _ready() -> void:
	_player = owner
	assert(_player, "PlayerEntity owner missing for " + name)
	_player.ready.connect(_initialize, CONNECT_ONE_SHOT)


func _initialize() -> void:
	# Receives from input controller, routes accepted attacks through animation controller
	_player.input_controller.attack_pressed.connect(_on_attack_pressed)

	_player.health.damaged.connect(_on_damaged_vibration)
	_player.health.died.connect(_player.player_movement_controller.disable_movement.bind(INF))


func _on_damaged_vibration(_attack: Attack) -> void:
	# TODO Change the gamepad index to the current player gamepad?
	Input.start_joy_vibration(0, 0.5, 0.5, 0.7)


func _on_attack_pressed() -> void:
	_player.try_melee_attack()
