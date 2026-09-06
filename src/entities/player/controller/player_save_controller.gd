# TODO It may be necessary to defer load data to after player has spawned? Maybe only in a multiplayer scenario though
## Player save controller component
class_name PlayerSaveController
extends Node

var _default_spawn_transform: Transform3D

@onready var player: PlayerEntity = owner

@onready var skills_controller: SkillsController = %SkillsController
@onready var economy_controller: EconomyController = %EconomyController
@onready var easter_egg_controller: EasterEggController = %EasterEggController


func _ready() -> void:
	assert(player != null, "Player owner missing in " + name)
	_default_spawn_transform = player.global_transform
	SaveManager.save_requested.connect(
		func(data: SaveData) -> void:
			build_save_data(data.player),
	)
	# Loading is triggered by game load manager
	SaveManager.reset_requested.connect(reset_save_data)


func build_save_data(data: PlayerSaveData) -> void:
	data.health = clampi(player.health.current_health, 1, player.health.max_health)

	data.unlocked_skill_ids = skills_controller.get_unlocked_ids()

	data.score = economy_controller.score
	data.gold = economy_controller.gold

	data.easter_eggs_found = easter_egg_controller.easter_eggs_found
	data.found_easter_egg_names = []

	# TODO Is this build or apply?
	for egg: EasterEgg.Name in easter_egg_controller.found_easter_eggs.keys():
		data.found_easter_egg_names.append(egg)


func apply_save_data(data: PlayerSaveData) -> void:
	player.health.current_health = data.health
	player.skills_controller.set_unlocked_ids(data.unlocked_skill_ids)

	economy_controller.score = data.score
	economy_controller.gold = data.gold
	economy_controller.score_changed.emit(data.score)
	economy_controller.gold_changed.emit(data.gold)

	easter_egg_controller.easter_eggs_found = data.easter_eggs_found
	easter_egg_controller.found_easter_eggs.clear()

	for egg: EasterEgg.Name in data.found_easter_egg_names:
		easter_egg_controller.found_easter_eggs[egg] = true


func reset_save_data() -> void:
	player.health.reset()
	player.skills_controller.reset()

	player.velocity = Vector3.ZERO
	player.global_transform = _default_spawn_transform

	economy_controller.score = 0
	economy_controller.gold = 0
	economy_controller.score_changed.emit(economy_controller.score)
	economy_controller.gold_changed.emit(economy_controller.gold)

	easter_egg_controller.easter_eggs_found = 0
	easter_egg_controller.found_easter_eggs.clear()
