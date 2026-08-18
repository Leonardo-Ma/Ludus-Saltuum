# https://godotsteam.com/tutorials/stats_achievements/
## Tracks achievement unlock state, uses Steam as source when running, else local save
extends Node

signal achievement_unlocked(key: StringName)

# TODO Remove hardcoded path
const _DATA_PATH: StringName = &"res://src/steam/achievements/achievement_registry_data.tres"
const _SAVE_PATH: String = "user://achievements.cfg"
const _SECTION: String = "unlocked"

# TODO Should not be hardcoded
const _ALL_SKILL_IDS: Array[StringName] = [&"dash", &"double_jump"]  #, &"feather_fall"]

var _by_key: Dictionary = {}  # Dictionary[StringName, AchievementDefinition]
var _unlocked: Dictionary = {}  # Dictionary[StringName, bool]


func _ready() -> void:
	if OS.has_feature("demo"):
		return

	var data: AchievementRegistryData = load(_DATA_PATH)
	assert(data != null, "Achievements: achievement_registry_data.tres not found in " + name)
	for definition: AchievementDefinition in data.definitions:
		assert(definition.key != &"", "Achievements: a definition has an empty key in " + name)
		_by_key[definition.key] = definition

	_load()
	GameEvents.score_updated.connect(_on_score_updated)
	GameEvents.easter_egg_found.connect(_on_easter_egg_found)
	GameEvents.player_spawned.connect(_on_player_spawned)
	GameEvents.status_buff_collected.connect(func(_e: StatusEffect, _i: Texture2D) -> void: _check_skill_completion())


func unlock(key: StringName) -> void:
	var definition: AchievementDefinition = _get_definition(key)

	if not _unlocked.get(key, false):
		_unlocked[key] = true
		_save()
		achievement_unlocked.emit(key)

	if Steam.isSteamRunning():
		Steam.setAchievement(definition.steam_api_name)
		Steam.storeStats()


#region Getters
func is_unlocked(key: StringName) -> bool:
	var definition: AchievementDefinition = _get_definition(key)
	if Steam.isSteamRunning():
		var result: Dictionary = Steam.getAchievement(definition.steam_api_name)
		if result.get("ret", false):
			return result.get("achieved", false)
	return _unlocked.get(key, false)


func get_display_name(key: StringName) -> String:
	var definition: AchievementDefinition = _get_definition(key)
	if Steam.isSteamRunning():
		var steam_name: String = Steam.getAchievementDisplayAttribute(definition.steam_api_name, "name")
		if steam_name != "":
			return steam_name
	return definition.display_name


func get_description(key: StringName) -> String:
	var definition: AchievementDefinition = _get_definition(key)
	if Steam.isSteamRunning():
		var steam_desc: String = Steam.getAchievementDisplayAttribute(definition.steam_api_name, "desc")
		if steam_desc != "":
			return steam_desc
	return definition.description


func get_icon(key: StringName, unlocked: bool) -> Texture2D:
	var definition: AchievementDefinition = _get_definition(key)
	if Steam.isSteamRunning():
		return get_steam_icon(key)
	return definition.icon_unlocked if unlocked else definition.icon_locked


func get_steam_icon(key: StringName) -> Texture2D:
	var definition: AchievementDefinition = _get_definition(key)
	var icon_handle: int = Steam.getAchievementIcon(definition.steam_api_name)
	if icon_handle == 0:
		return null
	var icon_size: Dictionary = Steam.getImageSize(icon_handle)
	var icon_buffer: Dictionary = Steam.getImageRGBA(icon_handle)

	var icon_image: Image = Image.create_from_data(icon_size.width, icon_size.height, false, Image.FORMAT_RGBA8, icon_buffer["buffer"])

	var icon_texture: ImageTexture = ImageTexture.create_from_image(icon_image)
	return icon_texture


func get_all_keys() -> Array[StringName]:
	var keys: Array[StringName] = []
	for key: StringName in _by_key:
		keys.append(key)
	return keys


func get_progress_ratio(key: StringName) -> float:
	var definition: AchievementDefinition = _get_definition(key)
	if definition.unlock_threshold <= 0:
		return 0.0
	return clampf(float(GameEvents.score) / float(definition.unlock_threshold), 0.0, 1.0)


## Sorted unlocked first, locked ordered closest to unlock second
func get_sorted_keys() -> Array[StringName]:
	var keys: Array[StringName] = get_all_keys()
	keys.sort_custom(_compare_unlock_priority)
	return keys


func _compare_unlock_priority(a: StringName, b: StringName) -> bool:
	var a_unlocked: bool = is_unlocked(a)
	var b_unlocked: bool = is_unlocked(b)
	if a_unlocked != b_unlocked:
		return a_unlocked
	return not a_unlocked and get_progress_ratio(a) > get_progress_ratio(b)


func _get_definition(key: StringName) -> AchievementDefinition:
	assert(_by_key.has(key), "Achievements: unknown key '%s' in %s" % [key, name] + ". Check AchievementRegistryData list")
	return _by_key[key]


#endregion


#region Unlocks
func _on_player_spawned(_player: Node) -> void:
	unlock(&"first_run")


func _on_score_updated(score: int) -> void:
	if score >= 100:
		unlock(&"score_100")
	if score >= 500:
		unlock(&"score_500")
	if score >= 2000:
		unlock(&"score_2000")
	if score >= 5000:
		unlock(&"score_5000")
	if score >= 10000:
		unlock(&"score_10000")


func _check_skill_completion() -> void:
	var player: PlayerEntity = get_tree().get_first_node_in_group(Groups.PLAYERS) as PlayerEntity
	var ids: Array[StringName] = player.skills_controller.get_unlocked_ids()
	if _ALL_SKILL_IDS.all(func(id: StringName) -> bool: return ids.has(id)):
		unlock(&"all_skills")


func _on_easter_egg_found(_easter_egg_name: StringName) -> void:
	var easter_eggs_found: int = GameEvents.easter_eggs_found
	if easter_eggs_found >= 1:
		unlock(&"first_easter_egg")
	#if easter_eggs_found >= 2:
	#unlock(&"second_easter_egg")
	#if easter_eggs_found >= 3:
	#unlock(&"third_easter_egg")


#endregion


#region Save and Load
func _save() -> void:
	var config: ConfigFile = ConfigFile.new()
	for key: StringName in _unlocked:
		config.set_value(_SECTION, key, _unlocked[key])
	config.save(_SAVE_PATH)


func _load() -> void:
	var config: ConfigFile = ConfigFile.new()
	if config.load(_SAVE_PATH) != OK:
		return
	for key: String in config.get_section_keys(_SECTION):
		_unlocked[StringName(key)] = config.get_value(_SECTION, key, false)
#endregion
