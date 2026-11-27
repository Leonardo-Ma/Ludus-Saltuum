# TODO It may be necessary to defer load data to after player has spawned? Maybe only in a multiplayer scenario though
class_name PlayerSaveController
extends SaveController

const SKILL_CATALOGUE: SkillCatalogue = preload("uid://6ygr0ieawafb") # skill_catalogue.tres

@onready var player: PlayerEntity = owner

@onready var skills_controller: SkillsController = %SkillsController
@onready var economy_controller: EconomyController = %EconomyController
@onready var easter_egg_controller: EasterEggController = %EasterEggController
@onready var status_manager: StatusManager = %StatusManager
@onready var cosmetics_controller: CosmeticsController = %CosmeticsController
@onready var _vehicle_rider: VehicleRider = %VehicleRider


func _child_ready() -> void:
	assert(player != null, "Player owner missing in " + name)
	assert(skills_controller and economy_controller and easter_egg_controller and status_manager and cosmetics_controller and _vehicle_rider, "Save dependencies missing in " + name)
	# NOTE Loading is triggered by game load manager


func _on_save_requested(data: SaveData) -> void:
	build_save_data(data.player)


func build_save_data(data: PlayerSaveData) -> void:
	data.health = clampi(player.health.current_health, 1, player.health.max_health)

	data.unlocked_skill_ids = []
	for definition: SkillDefinition in skills_controller.get_unlocked_skills():
		data.unlocked_skill_ids.append(definition.id)

	data.score = economy_controller.score
	data.gold = economy_controller.gold
	data.acquired_cosmetic_ids = cosmetics_controller.get_acquired_ids()
	data.equipped_ids = cosmetics_controller.get_equipped_ids()

	data.found_easter_egg_names = []

	# TODO Is this build or apply?
	for egg: EasterEgg.Name in easter_egg_controller.found_easter_eggs.keys():
		data.found_easter_egg_names.append(egg)


func apply_save_data(data: PlayerSaveData) -> void:
	player.health.current_health = data.health
	player.health.start_regeneration()

	var skills: Array[SkillDefinition] = []
	for skill_id: StringName in data.unlocked_skill_ids:
		var definition: SkillDefinition = SKILL_CATALOGUE.find_by_id(skill_id)
		if definition == null:
			push_warning("Save references unknown skill '%s', skipped" % [skill_id])
			continue
		skills.append(definition)
	skills_controller.set_unlocked_skills(skills)

	economy_controller.score = data.score
	economy_controller.gold = data.gold
	economy_controller.score_changed.emit(data.score)
	economy_controller.gold_changed.emit(data.gold)

	cosmetics_controller.set_acquired_ids(data.acquired_cosmetic_ids)
	cosmetics_controller.set_equipped_ids(data.equipped_ids)

	easter_egg_controller.found_easter_eggs.clear()
	for egg: EasterEgg.Name in data.found_easter_egg_names:
		easter_egg_controller.found_easter_eggs[egg] = true


func initialize_new_save_data() -> void:
	exit_vehicle_for_load()

	player.revive()
	skills_controller.reset()
	status_manager.clear_temporary_statuses()

	player.velocity = Vector3.ZERO
	player.global_transform = player.starting_transform
	player.finish_load()

	economy_controller.score = 0
	economy_controller.gold = 0
	economy_controller.score_changed.emit(economy_controller.score)
	economy_controller.gold_changed.emit(economy_controller.gold)

	cosmetics_controller.reset()

	easter_egg_controller.found_easter_eggs.clear()


func exit_vehicle_for_load() -> void:
	if _vehicle_rider.is_in_vehicle:
		_vehicle_rider.vehicle.exit(player.global_position)
