extends Node

## Tracks achievement unlock state, uses Steam as source when running, else local save

signal achievement_unlocked(id: AchievementDefinition.Id)

const ACHIEVEMENT_REGISTRY_DATA: AchievementRegistryData = preload("uid://rvm76nrub6ue")
const _SAVE_PATH: String = "user://achievements.cfg"
const _SECTION: String = "unlocked"

const _SKILL_CATALOGUE: SkillCatalogue = preload("uid://6ygr0ieawafb")
const _ALL_SKILLS: Array[SkillDefinition] = _SKILL_CATALOGUE.definitions

var _definitions: Dictionary[AchievementDefinition.Id, AchievementDefinition] = { }
var _unlocked: Dictionary[AchievementDefinition.Id, bool] = { }

var _economy_controller: EconomyController
var _skills_controller: SkillsController
var _easter_egg_controller: EasterEggController
var _score: int = 0

var _backend: AchievementBackend


func _ready() -> void:
	if OS.has_feature("demo"):
		return

	configure_achievement_backend(SteamAchievementBackend.new())

	var data: AchievementRegistryData = ACHIEVEMENT_REGISTRY_DATA
	assert(data != null, "Achievements: achievement_registry_data.tres not found in " + name)

	for definition: AchievementDefinition in data.definitions:
		assert(definition.id != AchievementDefinition.Id.UNDEFINED, "Achievements: a definition has UNDEFINED id in " + name)
		assert(not _definitions.has(definition.id), "Achievements: duplicate id " + _id_to_key(definition.id) + " in " + name)
		_definitions[definition.id] = definition

	_load()

	ControlledEntityEvents.player_finished_spawning.connect(_on_player_spawned)

	CollectiblesEvents.skill_collected.connect(
		func(_skill_definition: SkillDefinition) -> void:
			_check_skill_completion(),
	)


func configure_achievement_backend(backend: AchievementBackend) -> void:
	_backend = backend


func unlock(id: AchievementDefinition.Id) -> void:
	if not _unlocked.get(id, false):
		print_debug("Trying to unlock " + _id_to_key(id) + " achievement")
		_unlocked[id] = true
		_save()
		achievement_unlocked.emit(id)
		print_debug("Unlocked " + _id_to_key(id) + " achievement")
		if _backend.is_available():
			var definition: AchievementDefinition = _get_definition(id)
			_backend.unlock(definition)
			print_debug("Also unlocked " + _id_to_key(id) + " achievement in " + str(_backend))


#region Getters

func is_unlocked(id: AchievementDefinition.Id) -> bool:
	var definition: AchievementDefinition = _get_definition(id)

	if _backend.is_available():
		return _backend.is_unlocked(definition)
	return _unlocked.get(id, false)


func get_display_name(id: AchievementDefinition.Id) -> String:
	var definition: AchievementDefinition = _get_definition(id)

	if _backend.is_available():
		return _backend.get_display_name(definition)

	return definition.display_name


func get_description(id: AchievementDefinition.Id) -> String:
	var definition: AchievementDefinition = _get_definition(id)

	if _backend.is_available():
		return _backend.get_description(definition)

	return definition.description


func get_icon(id: AchievementDefinition.Id, unlocked: bool) -> Texture2D:
	var definition: AchievementDefinition = _get_definition(id)

	if _backend.is_available():
		return _backend.get_icon(definition)

	return definition.icon_unlocked if unlocked else definition.icon_locked


func get_all_ids() -> Array[AchievementDefinition.Id]:
	var ids: Array[AchievementDefinition.Id] = []

	for id: AchievementDefinition.Id in _definitions:
		ids.append(id)

	return ids


func get_progress_ratio(id: AchievementDefinition.Id) -> float:
	var definition: AchievementDefinition = _get_definition(id)

	if definition.unlock_threshold <= 0:
		return 0.0

	return clampf(float(_score) / float(definition.unlock_threshold), 0.0, 1.0)


## Sorted unlocked first, locked ordered closest to unlock second
func get_sorted_ids() -> Array[AchievementDefinition.Id]:
	var ids: Array[AchievementDefinition.Id] = get_all_ids()
	ids.sort_custom(_compare_unlock_priority)
	return ids


func _compare_unlock_priority(a: AchievementDefinition.Id, b: AchievementDefinition.Id) -> bool:
	var a_unlocked: bool = is_unlocked(a)
	var b_unlocked: bool = is_unlocked(b)

	if a_unlocked != b_unlocked:
		return a_unlocked

	return not a_unlocked and get_progress_ratio(a) > get_progress_ratio(b)


func _get_definition(id: AchievementDefinition.Id) -> AchievementDefinition:
	assert(_definitions.has(id), "Achievements: unknown id '%s' in %s. Check AchievementRegistryData list" % [_id_to_key(id), name])

	return _definitions[id]

#endregion


#region Unlocks

func _on_player_spawned(player: PlayerEntity) -> void:
	_economy_controller = player.economy_controller
	_skills_controller = player.skills_controller
	_easter_egg_controller = player.easter_egg_controller
	_easter_egg_controller.found.connect(_on_easter_egg_found)

	if not _economy_controller.score_changed.is_connected(_on_score_changed):
		_economy_controller.score_changed.connect(_on_score_changed)

	_score = _economy_controller.score

	_check_skill_completion()


func _on_score_changed(score: int) -> void:
	_score = score

	if score >= 1:
		unlock(AchievementDefinition.Id.FIRST_RUN)
	if score >= 100:
		unlock(AchievementDefinition.Id.SCORE_100)
	if score >= 500:
		unlock(AchievementDefinition.Id.SCORE_500)
	if score >= 2000:
		unlock(AchievementDefinition.Id.SCORE_2000)
	#if score >= 5000:
	#	unlock(&"score_5000")
	if score >= 10000:
		unlock(AchievementDefinition.Id.SCORE_10000)


func _check_skill_completion() -> void:
	if not is_instance_valid(_skills_controller):
		return

	var skills: Array[SkillDefinition] = _skills_controller.get_unlocked_skills()

	if _ALL_SKILLS.all(
		func(skill: SkillDefinition) -> bool:
			return skills.has(skill),
	):
		unlock(AchievementDefinition.Id.ALL_SKILLS)


func _on_easter_egg_found(_easter_egg_name: EasterEgg.Name) -> void:
	var easter_eggs_found: int = _easter_egg_controller.found_easter_eggs.size()

	if easter_eggs_found >= 1:
		unlock(AchievementDefinition.Id.FIRST_EASTER_EGG)

	#if easter_eggs_found >= 2:
	#unlock(&"second_easter_egg")
	#if easter_eggs_found >= 3:
	#unlock(&"third_easter_egg")

#endregion


#region Save and Load

func _save() -> void:
	var config: ConfigFile = ConfigFile.new()

	for id: AchievementDefinition.Id in _unlocked:
		config.set_value(_SECTION, _id_to_key(id), _unlocked[id])

	config.save(_SAVE_PATH)


func _load() -> void:
	var config: ConfigFile = ConfigFile.new()

	if config.load(_SAVE_PATH) != OK:
		return

	for key: String in config.get_section_keys(_SECTION):
		var member: String = key.to_upper()
		if not AchievementDefinition.Id.has(member):
			continue
		var id: AchievementDefinition.Id = AchievementDefinition.Id[member] as AchievementDefinition.Id
		_unlocked[id] = config.get_value(_SECTION, key, false)


func _id_to_key(id: AchievementDefinition.Id) -> String:
	return str(AchievementDefinition.Id.find_key(id)).to_lower()

# TODO Add a reset achievements that is tied to save and doesn't impact steam / backend
#endregion
