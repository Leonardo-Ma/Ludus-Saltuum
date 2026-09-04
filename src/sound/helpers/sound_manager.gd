extends Node

enum SoundCategory {
	UNASSIGNED = 0,
	GLOBAL = 1,
	MUSIC = 2,
	SFX = 3,
	AMBIENT = 4,
	UI = 5,
	VOICE = 6,
	VEHICLE = 7,
}

const BUS_NAMES: Dictionary[SoundCategory, String] = {
	SoundCategory.GLOBAL: "Master",
	SoundCategory.MUSIC: "Music",
	SoundCategory.SFX: "SFX",
	SoundCategory.AMBIENT: "Ambient",
	SoundCategory.UI: "UI",
	SoundCategory.VOICE: "Voice",
	SoundCategory.VEHICLE: "Vehicle",
}

var music: MusicController
var combat: CombatPrioritySoundController
var pool: SoundPool


func _ready() -> void:
	_create_subsystems()

	combat.initialize(pool)
	music.initialize(pool)
	_load_volume_settings()


func _create_subsystems() -> void:
	pool = SoundPool.new()
	pool.name = "SoundPool"
	add_child(pool)

	music = MusicController.new()
	music.name = "MusicController"
	add_child(music)

	combat = CombatPrioritySoundController.new()
	combat.name = "CombatPrioritySoundController"
	add_child(combat)

#region Public API
func play_sound(sound: AudioStream, category: SoundCategory, position: Vector3 = Vector3.ZERO) -> void:
	pool.play_sound(sound, category, position)


func play_combat_sound(sound: AudioStream, position: Vector3, priority: int = 0) -> void:
	combat.play_with_priority(sound, position, priority)


func play_music(track: AudioStream, fade_duration: float = 1.0) -> void:
	music.play(track, fade_duration)


func change_music_state(state: MusicController.MusicState, immediate: bool = false, track_key: String = "") -> void:
	music.change_state(state, immediate, track_key)


func stop_music(fade_duration: float = 1.0) -> void:
	music.stop(fade_duration)


func set_category_volume(category: SoundCategory, volume_db: float) -> void:
	var bus_name: String = _get_bus_for_category(category)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(bus_name), volume_db)
	_save_volume_settings()


func get_category_volume(category: SoundCategory) -> float:
	var bus_name: String = _get_bus_for_category(category)
	return AudioServer.get_bus_volume_db(AudioServer.get_bus_index(bus_name))


func mute_all() -> void:
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), true)


func unmute_all() -> void:
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), false)


func pause_all_sfx(paused: bool) -> void:
	pool.pause_category(SoundCategory.SFX, paused)
	pool.pause_category(SoundCategory.AMBIENT, paused)
	pool.pause_category(SoundCategory.VOICE, paused)

#endregion

#region Private helpers
func _get_bus_for_category(category: SoundCategory) -> String:
	assert(BUS_NAMES.has(category), "SoundManager: unhandled SoundCategory in " + name)
	return BUS_NAMES[category]


func _load_volume_settings() -> void:
	var config: ConfigFile = ConfigFile.new()
	if config.load("user://audio_settings.cfg") == OK:
		for category: int in SoundCategory.values():
			if category == SoundCategory.UNASSIGNED:
				continue
			var bus: String = _get_bus_for_category(category as SoundCategory)
			var volume: float = config.get_value("volumes", bus, 0.0)
			AudioServer.set_bus_volume_db(AudioServer.get_bus_index(bus), volume)


func _save_volume_settings() -> void:
	var config: ConfigFile = ConfigFile.new()
	for category: int in SoundCategory.values():
		if category == SoundCategory.UNASSIGNED:
			continue
		var bus: String = _get_bus_for_category(category as SoundCategory)
		var volume: float = AudioServer.get_bus_volume_db(AudioServer.get_bus_index(bus))
		config.set_value("volumes", bus, volume)
	config.save("user://audio_settings.cfg")
#endregion
