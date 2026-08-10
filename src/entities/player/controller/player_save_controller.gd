# TODO It may be necessary to defer load data to after player has spawned? Maybe only in a multiplayer scenario though
class_name PlayerSaveController
extends Node

@onready var player: Node3D = $"../.."


func build_save(data: PlayerSaveData) -> void:
	data.score = GameEvents.score
	data.gold = GameEvents.gold
	data.easter_eggs_found = GameEvents.easter_eggs_found
	data.found_easter_egg_names = []
	data.health = clampi(player.health.current_health, 0, player.health.max_health)
	data.unlocked_skill_ids = player.skills_controller.get_unlocked_ids()

	# TODO Is this build or apply?
	for egg: StringName in GameEvents.found_easter_eggs.keys():
		data.found_easter_egg_names.append(egg)


func apply_save(data: PlayerSaveData) -> void:
	player.health.current_health = maxi(data.health, 1)

	# TODO Maybe an assert here?
	for id: StringName in data.unlocked_skill_ids:
		var def: SkillDefinition = SkillRegistry.get_definition(id)
		if def:
			player.skills_controller.unlock(def)

	GameEvents.score = data.score
	GameEvents.gold = data.gold
	GameEvents.score_updated.emit(data.score)
	GameEvents.gold_updated.emit(data.gold)

	GameEvents.easter_eggs_found = data.easter_eggs_found

	for egg: StringName in data.found_easter_egg_names:
		GameEvents.found_easter_eggs[egg] = true


func reset_data() -> void:
	player.health.reset()
	player.skills_controller.reset()

	player.transform = Transform3D.IDENTITY
	player.velocity = Vector3.ZERO

	GameEvents.score = 0
	GameEvents.gold = 0
	GameEvents.score_updated.emit(GameEvents.score)
	GameEvents.gold_updated.emit(GameEvents.gold)

	GameEvents.easter_eggs_found = 0
	GameEvents.found_easter_eggs.clear()
