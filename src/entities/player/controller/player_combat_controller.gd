class_name PlayerCombatController
extends Node

## Routes player input and health events to combat reactions

var _player: PlayerEntity
var _initialized: bool = false


func _ready() -> void:
	_initialize.call_deferred()


func _initialize() -> void:
	_player = owner as PlayerEntity
	assert(_player != null, "PlayerEntity owner missing for " + name)

	_initialized = true
	# Receives from input controller, goes to animation controller for attack
	owner.input_controller.attack_pressed.connect(owner.melee_attacked.emit)

	owner.health.damaged.connect(_on_damaged_vibration)
	# TODO Also disable input controller, player can attack between death and respawn
	owner.health.died.connect(owner.player_movement_controller.disable_movement.bind(INF))


func _on_damaged_vibration(_attack: Attack) -> void:
	# TODO Change the gamepad index to the current player gamepad?
	Input.start_joy_vibration(0, 0.5, 0.5, 0.7)
