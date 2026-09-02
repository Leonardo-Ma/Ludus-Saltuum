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
	# Loading is triggered by game load manager
	SaveManager.reset_requested.connect(reset_data)


func build_save(data: PlayerSaveData) -> void:
	data.score = EconomyManager.score
	data.gold = EconomyManager.gold
	data.easter_eggs_found = EasterEggManager.easter_eggs_found
	data.found_easter_egg_names = []
	data.health = clampi(player.health.current_health, 1, player.health.max_health)
	data.unlocked_skill_ids = player.skills_controller.get_unlocked_ids()

	# TODO Is this build or apply?
	for egg: StringName in EasterEggManager.found_easter_eggs.keys():
		data.found_easter_egg_names.append(egg)


func apply_save(data: PlayerSaveData) -> void:
	player.health.current_health = data.health
	player.skills_controller.set_unlocked_ids(data.unlocked_skill_ids)

	EconomyManager.score = data.score
	EconomyManager.gold = data.gold
	EconomyManager.score_updated.emit(data.score)
	EconomyManager.gold_updated.emit(data.gold)

	EasterEggManager.easter_eggs_found = data.easter_eggs_found
	EasterEggManager.found_easter_eggs.clear()

	for egg: StringName in data.found_easter_egg_names:
		EasterEggManager.found_easter_eggs[egg] = true


func reset_data() -> void:
	player.health.reset()
	player.skills_controller.reset()

	player.velocity = Vector3.ZERO
	player.global_transform = _default_spawn_transform

	EconomyManager.score = 0
	EconomyManager.gold = 0
	EconomyManager.score_updated.emit(EconomyManager.score)
	EconomyManager.gold_updated.emit(EconomyManager.gold)

	EasterEggManager.easter_eggs_found = 0
	EasterEggManager.found_easter_eggs.clear()
