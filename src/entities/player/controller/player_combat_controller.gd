class_name PlayerCombatController
extends Node

## Routes player input and health events to combat reactions

var _player: PlayerEntity
var _initialized: bool = false


func _ready() -> void:
	_initialize.call_deferred()


func _initialize() -> void:
	_player = owner
	assert(_player, "PlayerEntity owner missing for " + name)

	_initialized = true
	# Receives from input controller, goes to animation controller for attack
	_player.input_controller.attack_pressed.connect(_on_attack_pressed)

	_player.health.damaged.connect(_on_damaged_vibration)
	# TODO Also disable input controller, player can attack between death and respawn
	_player.health.died.connect(_player.player_movement_controller.disable_movement.bind(INF))


func _on_damaged_vibration(_attack: Attack) -> void:
	# TODO Change the gamepad index to the current player gamepad?
	Input.start_joy_vibration(0, 0.5, 0.5, 0.7)


func _on_attack_pressed() -> void:
	if not _player.attack_component.can_attack():
		return
	_player.attack_component.start_cooldown()
	_player.melee_attacked.emit()
