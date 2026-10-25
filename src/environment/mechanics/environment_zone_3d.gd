## Change player's camera to use target environment while inside
class_name EnvironmentZone3D
extends Area3D

const THUNDER_SOUNDS: Array[AudioStream] = [
	preload("uid://dsk5roghsbtm3"), # thunder_1_near
	preload("uid://cws8ps85wa78n"), # thunder_5_near
]

@export var target_environment: Environment

@export var play_thunder_on_enter: bool = false


func _ready() -> void:
	assert(target_environment != null, "Target Environment is not assigned for " + name)

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node3D) -> void:
	if not body.is_in_group(Groups.PLAYERS):
		return

	var player: PlayerEntity = body as PlayerEntity
	assert(player != null, "Node in Groups.PLAYERS is not a PlayerEntity: " + body.name)

	var controller: EnvironmentTransitionController = player.environment_transition_controller
	assert(controller != null, "EnvironmentTransitionController child is missing for " + player.name)

	if play_thunder_on_enter:
		AudioManager.play_sound(THUNDER_SOUNDS.pick_random(), AudioManager.SoundBus.SFX, player.global_position + Vector3(0.0, 5.0, 0.0))

	await controller.enter_zone(self, target_environment)


func _on_body_exited(body: Node3D) -> void:
	if not body.is_in_group(Groups.PLAYERS):
		return

	var player: PlayerEntity = body as PlayerEntity
	assert(player != null, "Node in Groups.PLAYERS is not a PlayerEntity: " + body.name)

	var controller: EnvironmentTransitionController = player.environment_transition_controller
	assert(controller != null, "EnvironmentTransitionController child is missing for " + player.name)

	await controller.exit_zone(self)
