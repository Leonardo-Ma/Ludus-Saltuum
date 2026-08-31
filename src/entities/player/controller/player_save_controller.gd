# TODO It may be necessary to defer load data to after player has spawned? Maybe only in a multiplayer scenario though
## Player save controller component
class_name PlayerSaveController
extends Node

var _default_spawn_transform: Transform3D

@onready var player: PlayerEntity = owner as PlayerEntity


func _ready() -> void:
	assert(player != null, "Player owner missing in " + name)

	_default_spawn_transform = player.global_transform
	SaveManager.save_requested.connect(func(data: SaveData) -> void: build_save(data.player))
	# Loading is done by game load manager


func build_save(data: PlayerSaveData) -> void:
	data.score = GameEvents.score
	data.gold = GameEvents.gold
	data.easter_eggs_found = GameEvents.easter_eggs_found
	data.found_easter_egg_names = []
	data.health = clampi(player.health.current_health, 1, player.health.max_health)
	data.unlocked_skill_ids = player.skills_controller.get_unlocked_ids()

	# TODO Is this build or apply?
	for egg: StringName in GameEvents.found_easter_eggs.keys():
		data.found_easter_egg_names.append(egg)


func apply_save(data: PlayerSaveData) -> void:
	player.health.current_health = data.health
	player.skills_controller.set_unlocked_ids(data.unlocked_skill_ids)

	GameEvents.score = data.score
	GameEvents.gold = data.gold
	GameEvents.score_updated.emit(data.score)
	GameEvents.gold_updated.emit(data.gold)

	GameEvents.easter_eggs_found = data.easter_eggs_found
	GameEvents.found_easter_eggs.clear()

	for egg: StringName in data.found_easter_egg_names:
		GameEvents.found_easter_eggs[egg] = true


func reset_data() -> void:
	player.health.reset()
	player.skills_controller.reset()

	player.velocity = Vector3.ZERO
	player.global_transform = _default_spawn_transform

	GameEvents.score = 0
	GameEvents.gold = 0
	GameEvents.score_updated.emit(GameEvents.score)
	GameEvents.gold_updated.emit(GameEvents.gold)

	GameEvents.easter_eggs_found = 0
	GameEvents.found_easter_eggs.clear()
