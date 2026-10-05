extends Node

enum SoundBus {
	UNASSIGNED = 0,
	MASTER = 1,
	MUSIC = 2,
	SFX = 3,
	UI = 4,
}

const BUS_NAMES: Dictionary[SoundBus, String] = { SoundBus.MASTER: "Master", SoundBus.MUSIC: "Music", SoundBus.SFX: "SFX", SoundBus.UI: "UI" }

const MIN_VOLUME_DB: float = -80.0

var _base_volume_db: Dictionary[SoundBus, float] = { }


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

#region Public API

func play_sound(sound: AudioStream, bus: SoundBus, position: Vector3) -> void:
	assert(sound != null, "AudioManager received null sound in " + name)

	var player: AudioStreamPlayer3D = AudioStreamPlayer3D.new()
	player.stream = sound
	player.bus = BUS_NAMES[bus]
	player.finished.connect(player.queue_free)
	add_child(player)
	player.global_position = position
	player.play()


func play_ui_sound(sound: AudioStream) -> void:
	assert(sound != null, "AudioManager received null UI sound in " + name)

	var player: AudioStreamPlayer = AudioStreamPlayer.new()
	player.stream = sound
	player.bus = BUS_NAMES[SoundBus.UI]
	player.finished.connect(player.queue_free)
	add_child(player)
	player.play()


## Persistence in SettingsManager, this only drives AudioServer
func set_bus_volume(bus: SoundBus, volume_db: float) -> void:
	var bus_name: String = BUS_NAMES[bus]
	var bus_index: int = AudioServer.get_bus_index(bus_name)
	assert(bus_index >= 0, "Audio bus missing in " + name + ": " + bus_name)

	AudioServer.set_bus_volume_db(bus_index, volume_db)


func get_bus_volume(bus: SoundBus) -> float:
	var bus_name: String = BUS_NAMES[bus]
	var bus_index: int = AudioServer.get_bus_index(bus_name)
	assert(bus_index >= 0, "Audio bus missing in " + name + ": " + bus_name)

	return AudioServer.get_bus_volume_db(bus_index)


## Slider 0..1 on squared taper, offset from bus layout volume
func set_bus_volume_linear(bus: SoundBus, slider_value: float) -> void:
	assert(slider_value >= 0.0 and slider_value <= 1.0, "Invalid volume slider value in " + name)

	var bus_name: String = BUS_NAMES[bus]
	var bus_index: int = AudioServer.get_bus_index(bus_name)
	assert(bus_index >= 0, "Audio bus missing in " + name + ": " + bus_name)

	if not _base_volume_db.has(bus):
		_base_volume_db[bus] = AudioServer.get_bus_volume_db(bus_index)

	if is_zero_approx(slider_value):
		AudioServer.set_bus_volume_db(bus_index, MIN_VOLUME_DB)
		return

	var volume_db: float = _base_volume_db[bus] + linear_to_db(slider_value * slider_value)
	AudioServer.set_bus_volume_db(bus_index, maxf(volume_db, MIN_VOLUME_DB))


func mute_all() -> void:
	var bus_index: int = AudioServer.get_bus_index(BUS_NAMES[SoundBus.MASTER])
	assert(bus_index >= 0, "Audio bus missing in " + name + ": " + BUS_NAMES[SoundBus.MASTER])

	AudioServer.set_bus_mute(bus_index, true)


func unmute_all() -> void:
	var bus_index: int = AudioServer.get_bus_index(BUS_NAMES[SoundBus.MASTER])
	assert(bus_index >= 0, "Audio bus missing in " + name + ": " + BUS_NAMES[SoundBus.MASTER])

	AudioServer.set_bus_mute(bus_index, false)


func pause_all_sfx(paused: bool) -> void:
	var sfx_buses: Array[SoundBus] = [SoundBus.SFX]

	for bus: SoundBus in sfx_buses:
		var bus_index: int = AudioServer.get_bus_index(BUS_NAMES[bus])
		assert(bus_index >= 0, "Audio bus missing in " + name + ": " + BUS_NAMES[bus])
		AudioServer.set_bus_mute(bus_index, paused)

#endregion
